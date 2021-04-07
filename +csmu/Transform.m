classdef Transform < handle & matlab.mixin.Copyable
   properties
      Rotation {mustBeNumeric, ...
         csmu.validators.mustBeVector(Rotation, [0, 1, 3])}
      Translation {mustBeNumeric, ...
         csmu.validators.mustBeVector(Translation, [0, 2, 3])}
      DoReverse (1, 1) logical = false
      InputView csmu.ImageRef
      OutputView csmu.ImageRef
      
      % RotationUnits
      % char (default is 'deg')
      %
      % either 'deg' or 'rad'
      RotationUnits (1, :) char ...
         {csmu.validators.mustBeValidRotationUnit} = 'deg'
      
      TranslationRotationOrder csmu.IndexOrdering ...
         {csmu.validators.mustBeScalarOrEmpty}
   end
   
   properties (GetAccess = 'private', SetAccess = 'private')
      AffineCache
   end
   
   properties (Dependent)
      AffineObj
      Affine2D
      Affine3D
      T
      IsTrivial
      Inverse
      NumDims
      
      % lowercase versions for backward compatibility
      rotation
      translation
      inputView
      outputView
   end
   
   properties (Constant)
      
   end
   
   methods
      function self = Transform(varargin)
         if nargin == 0
            return
         end
         
         inputType = '';         
         if isnumeric(varargin{1})
            if isequal(size(varargin{1}), [4, 4])
               inputType = 'transformMatrix';
            else
               inputType = 'objectArraySize';
            end
         elseif isa(varargin{1}, 'affine3d') || isa(varargin{1}, 'affine2d')
            inputType = 'affineObject';
         elseif isa(varargin{1}, 'csmu.Transform')
            inputType = 'transformObject';
         end
         
         switch inputType
            case 'objectArraySize'
               sz = csmu.parseSizeArgs(varargin{:});
               if isempty(sz) || any(cell2mat(sz) == 0)
                  self = self.emptyFun(sz{:});
               else
                  self(sz{:}) = copy(self);
               end
               
            case 'affineObject'
               assert(length(varargin) == 1, ['Only one scalar (or ', ...
                  'array) of affine transform objects can be passed to ', ...
                  'initialize a Transform object.']);
               affObj = varargin{1};
               sz = num2cell(size(affObj));
               self(sz{:}) = self;
               for iObj = 1:length(affObj)                  
                  self(iObj).AffineObj = affObj(iObj);
               end
               
            case 'transformMatrix'
               assert(length(varargin) == 1, ['Only one transform matrix', ...
                  'can be passed to initialize a Transform object.']);
               self.T = varargin{1};
            
            case 'transformObject'
               assert(length(varargin) == 1, ['Only one Transform object', ...
                  'can be passed to initialize a Transform object.']);
               csmu.Transform.copyObject(varargin{1}, self);
            
            otherwise
               error('Unexpected input');
         end
      end
      
      function P = warpPoints(self, P)         
         P = self.AffineObj.transformPointsForward(P);
      end
      
      function [varargout] = warpImage(self, I, varargin)
         L = csmu.Logger('csmu.Transform.warpImage');

         persistent tformCache
         if (ischar(I) || isstring(I)) && strcmpi(I, 'clear') 
            L.debug('Clearing tformCache.');
            tformCache = [];
            return
         end
         
         % parse inputs
         ip = inputParser;
         ip.addParameter('WarpArgs', {}, @(x) iscell(x));
         ip.addParameter('Save', false, @(x) islogical(x) && isscalar(x));
         ip.parse(varargin{:});
         warpParams = ip.Results.WarpArgs;
         doSave = ip.Results.Save;
         
         if self.DoReverse
            RA = self.OutputView;
            RB = self.InputView;
         else
            RA = self.InputView;
            RB = self.OutputView;
         end
         
         if isempty(RA)
            % set volume to be centered on origin using a spatial reference
            RA = csmu.centerImRef(size(I));
         end
        
         if ~isempty(RB)            
            warpParams = [warpParams, {'OutputView'}, {RB}];
         end
         
         % no transformation just, potentially, a view change         
         if self.IsTrivial
            L.debug('Performing trivial transform.')
            if isempty(RB)
               B = I;
               RB = RA;
            else
               B = csmu.changeView(I, RA, RB);
            end
         else % (not a trivial transform)
            L.assert(~islogical(I), 'Cannot transform a logical array.')
            L.assert(isreal(I), strcat('Cannot transform an array with', ...
               ' imaginary components.'));
            cacheLength = length(tformCache);
            doLoad = 0;
            warpArgs = [{RA, self.AffineObj}, warpParams];
            for iCached = 1:cacheLength
               cachedArgs = tformCache(iCached).tformArgs;
               if isequal(warpArgs, cachedArgs)
                  if ~isempty(tformCache(iCached).indexMap)
                     doLoad = iCached;
                  end
                  break
               end
            end
            if ~doLoad
               L.debug('Performing non-trivial transformation.');
               if doSave
                  [B, RB, indexMap] = csmu.affinewarp(I, warpArgs{:});
                  if isempty(tformCache), tformCache = struct; end
                  i = cacheLength + 1;
                  tformCache(i).tformArgs = warpArgs;
                  tformCache(i).RB = RB;
                  tformCache(i).indexMap = indexMap;
                  tformCache(i).class = class(B);
               else % (don't save)
                  [B, RB] = csmu.affinewarp(I, warpArgs{:});
               end
            else % (do load)
               L.debug('Loading transform from `tformCache`.');
               t1 = tic;
               B = csmu.affinewarp(I, tformCache.tformArgs{:}, ...
                  'IndexMap', tformCache(doLoad).indexMap);
               L.debug('   ... cached transform took %.2f s.', toc(t1));
               RB = tformCache(doLoad).RB;
            end
         end
         
         switch nargout
            case 1
               varargout = {B};
            otherwise
               varargout = {B, RB};
         end
      end
      
      function imref = warpRef(self, imref)
         imref = csmu.ImageRef(imref);       
         newOutLims = cell(1, self.NumDims);
         [newOutLims{:}] = self.outputLimits(imref.WorldLimits{:});
         imref = csmu.ImageRef;
         imref.WorldLimits = newOutLims;
      end

      function [varargout] = outputLimits(self, varargin)
         varargout = cell(1, self.NumDims);
         [varargout{:}] = self.AffineObj.outputLimits(varargin{:});
      end
            
      function P = applyToPoints(self, P)
         L = csmu.Logger('csmu.Transform.applyToPoints');
         L.warn('Transform.applyToPoints is deprecated, use ''warpPoints''');
         P = self.warpPoints(P);
      end
      
      % adapted from dftransform
      function [varargout] = apply(self, I, varargin)        
         L = csmu.Logger('csmu.Transform.apply');
         L.warn('Transform.apply is deprecated, use ''warpImage''');
         varargout = cell(1, nargout);
         [varargout{:}] = self.warpImage(I, varargin{:});
      end
         
      function set.AffineObj(self, val)
         assert(any(strcmpi(class(val), {'affine3d', 'affine2d'})));
         self.AffineCache = val;
      end
      
      function set.Affine3D(self, val)
         assert(isa(val, 'affine3d'));
         self.AffineCache = val;
      end
      
      function set.Affine2D(self, val)
         assert(isa(val, 'affine2d'));
         self.AffineCache = val;
      end
      
      function out = get.Inverse(self)
         % FIXME ... this could cause an issue with subclasses
         out = csmu.Transform(self.AffineObj.invert);
      end
      
      function out = get.Affine3D(self)
         assert(self.NumDims == 3);
         out = self.AffineObj;
      end
      
      function out = get.Affine2D(self)
         assert(self.NumDims == 2);
         out = self.AffineObj;
      end
         
      function out = get.NumDims(self)
         switch class(self.AffineObj)
            case 'affine2d'
               out = 2;
            case 'affine3d'
               out = 3;
         end
      end
      
      function out = get.AffineObj(self)
         L = csmu.Logger('csmu.Transform.get.AffineObj');
         if ~isempty(self.AffineCache)
            if ~isempty(self.Rotation) || ~isempty(self.Translation)
               L.warn(['Defaulting to use the provided the AffineObj \n', ...
                  'object rather than one constructed from the rotation \n',...
                  'and/or translation vectors. To prevent this warning \n', ...
                  'message set either the AffineObj property or both \n', ...
                  'Rotation and Translation properties to an empty array.']);
            end
            out = self.AffineCache;
            if self.DoReverse
               out = out.invert;
            end
         else
            if isempty(self.Rotation) && isempty(self.Translation)
               L.warn('Defaulting to return an affine3d object');
               out = affine3d();
            else
               [rot, trans] = deal([]);
               idxOrder = self.TranslationRotationOrder;
               if ~isempty(self.Rotation)
                  if isempty(idxOrder)
                     L.warn(['`Rotation` property is defaulting to order ', ...
                        'by row-col not x-y; specify the ', ...
                        '`TranslationRotationOrder` property to suppress ', ...
                        'this warning.']);
                     rot = self.Rotation;
                  else
                     rot = idxOrder.toRowCol(self.Rotation, ...
                        csmu.IndexType.VECTOR);
                  end
                  
                  if strcmpi(self.RotationUnits, 'rad')
                     rot = rad2deg(rot);
                  end
                  
                  if isempty(self.Translation)
                     if length(rot) == 1
                        trans = [0 0];
                     else
                        trans = [0 0 0];
                     end
                  end
               end
               if ~isempty(self.Translation)
                  if isempty(idxOrder)
                     L.warn(['`Translation` property is defaulting to ', ...
                        'order by row-col not x-y; specify the ', ...
                        '`TranslationRotationOrder` property to suppress ', ...
                        'this warning.']);
                     trans = self.Translation;
                  else
                     trans = idxOrder.toRowCol(self.Translation, ...
                        csmu.IndexType.VECTOR);
                  end
                  if isempty(self.Rotation)
                     if length(trans) == 2
                        rot = 0;
                     else
                        rot = [0 0 0];
                     end
                  end
               end
               out = csmu.df2tform(rot, trans, self.DoReverse);
            end
         end
      end
      
      function emptyObj = emptyFun(~, varargin)
         emptyObj = csmu.Transform.empty(varargin{:});
      end
      
      function out = get.IsTrivial(self)
         out = isequal(self.T, eye(4));
      end
      
      function out = get.T(self)
         out = self.AffineObj.T;
      end
      
      function set.T(self, val)
         try
            affObj = affine3d(val);
         catch
            affObj = csmu.standard2matlabAffine(val);
         end
         self.AffineObj = affObj;
      end
      
      function out = get.rotation(self)
         out = self.Rotation;
      end
      
      function set.rotation(self, val)
         self.Rotation = val;
      end     
      
      function out = get.translation(self)
         out = self.Translation;
      end
      
      function set.translation(self, val)
         self.Translation = val;
      end
      
      function out = get.inputView(self)
         out = self.InputView;
      end
      
      function set.inputView(self, val)
         self.InputView = val;
      end
      
      function out = get.outputView(self)
         out = self.OutputView;
      end
      
      function set.outputView(self, val)
         self.OutputView = val;
      end
      
      function out = mtimes(self, obj)
         out = csmu.Transform;
         if self.NumDims == 2
            out.AffineObj = affine2d(self.T * obj.T);
         else
            out.AffineObj = affine3d(self.T * obj.T);
         end
         out = self.copyObject(out, self);
      end      
   end
   
   methods (Static)
      function clearWarpImage
         T = csmu.Transform;
         T.warpImage('clear');
      end
      
      function outObj = copyObject(inObj, outObj)
         mc = metaclass(inObj);
         props = mc.Properties;
         for iProp = 1:length(props)
            if ~props{iProp}.Dependent ...
                  && ~strcmpi(props{iProp}.SetAccess, 'none')
               outObj.(props{iProp}.Name) = inObj.(props{iProp}.Name);
            end
         end
      end
   end
end


