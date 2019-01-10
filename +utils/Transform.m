classdef Transform < handle & matlab.mixin.Copyable
   properties
      Rotation {mustBeNumeric, ...
         utils.validators.mustBeVector(Rotation, [0 3])}
      Translation {mustBeNumeric, ...
         utils.validators.mustBeVector(Translation, [0 3])}
      DoReverse (1, 1) logical = false
      InputView imref3d
      OutputView imref3d
      
      % RotationUnits
      % char (default is 'deg')
      %
      % either 'deg' or 'rad'
      RotationUnits (1, :) char ...
         {utils.validators.mustBeValidRotationUnit} = 'deg'
   end
   
   properties (GetAccess = 'private', SetAccess = 'private')
      Affine3DCache
   end
   
   properties (Dependent)
      Affine3D
      T
      IsTrivial
      
      % lowercase versions for backward compatibility
      rotation
      translation
      inputView
      outputView
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
               inputType = 'arraySize';
            end
         elseif isa(varargin{1}, 'affine3d')
            inputType = 'affineObject';
         elseif isa(varargin{1}, 'utils.Transform')
            inputType = 'transformObject';
         end
         
         switch inputType
            case 'arraySize'
               if length(varargin) == 1
                  sz = varargin{1};
                  assert(isvector(sz) || isempty(sz));
                  if isempty(sz)
                     self = self.emptyFun;
                     return
                  elseif length(sz) == 1
                     sz = {sz, sz};
                  else                     
                     sz = num2cell(sz);
                  end
               else
                  sz = varargin;
               end
               self(sz{:}) = self;
               for iArr = 1:prod(sz{:})
                  idx = sz;
                  [idx{:}] = ind2sub(cell2mat(sz), iArr);
                  self(idx{:}) = copy(self(end));
               end
               
            case 'affineObject'
               assert(length(varargin) == 1, ['Only one scalar (or ', ...
                  'array) of affine transform objects can be passed to ', ...
                  'initialize a Transform object.']);
               affObj = varargin{1};
               sz = num2cell(size(affObj));
               self(sz{:}) = self;
               for iObj = 1:length(affObj)                  
                  self(iObj).Affine3D = affObj(iObj);
               end
               
            case 'transformMatrix'
               assert(length(varargin) == 1, ['Only one transform matrix', ...
                  'can be passed to initialize a Transform object.']);
               self.T = varargin{1};
            
            case 'transformObject'
               assert(length(varargin) == 1, ['Only one Transform object', ...
                  'can be passed to initialize a Transform object.']);
               utils.Transform.copyObject(varargin{1}, self);
            
            otherwise
               error('Unexpected input');
         end
      end
      
      function P = applyToPoints(self, P)
         P = self.Affine3D.transformPointsForward(P);
      end
      
      % adapted from dftransform
      function [varargout] = apply(self, A, varargin)                  
         L = utils.Logger('utils.Transform.apply');
         persistent tformCache
         if (ischar(A) || isstring(A)) && strcmpi(A, 'clear')
            L.debug('Clearing tformCache.');
            tformCache = [];
            return
         end
         
         % parse inputs
         ip = inputParser;
         ip.addParameter('WarpArgs', {}, @(x) iscell(x));
         ip.addParameter('Save', false, @(x) islogical(x) && isscalar(x));
         ip.parse(varargin{:});
         warpArgs = ip.Results.WarpArgs;
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
            RA = utils.centerImRef(size(A));
         end
        
         if ~isempty(RB)            
            warpArgs = [warpArgs, {'OutputView'}, {RB}];
         end
         
         % no transformation just, potentially, a view change         
         if self.IsTrivial
            L.debug('Performing trivial transform')
            if isempty(RB)
               B = A;
               RB = RA;
            else
               B = utils.changeView(A, RA, RB);
            end
         else % (not trivial)
            cacheLength = length(tformCache);
            doLoad = 0;
            for iCached = 1:cacheLength
               if isequal(self, tformCache(iCached).tform)
                  doLoad = iCached;
                  break
               end
            end
            if ~doLoad
               if doSave
                  [B, RB, Aidx, Bfilt] = utils.affinewarp(A, RA, ...
                     self.Affine3D, warpArgs{:});
                  if isempty(tformCache), tformCache = struct; end
                  i = cacheLength + 1;
                  tformCache(i).tform = copy(self);
                  tformCache(i).RB = RB;
                  tformCache(i).Bfilt = Bfilt;
                  tformCache(i).Aidx = Aidx;
                  tformCache(i).class = class(B);
               else % (don't save)
                  [B, RB] = utils.affinewarp(A, RA, self.Affine3D, warpArgs{:});
               end
            else % (do load)
               B = zeros(tformCache(doLoad).RB.ImageSize, ...
                  tformCache(doLoad).class);
               B(tformCache(doLoad).Bfilt) = A(tformCache(doLoad).Aidx);
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
         
      function set.Affine3D(self, val)
         self.Affine3DCache = val;
      end
      
      function out = get.Affine3D(self)
         L = utils.Logger('utils.Transform.get.Affine3D');
         if ~isempty(self.Affine3DCache)
            if ~isempty(self.Rotation) || ~isempty(self.Translation)
               L.warn(['Defaulting to use the provided the Affine3D \n', ...
                  'object rather than one constructed from the rotation \n',...
                  'and/or translation vectors. To prevent this warning \n', ...
                  'message set either the Affine3D property or both \n', ...
                  'Rotation and Translation properties to an empty array.']);
            end
            out = self.Affine3DCache;
            if self.DoReverse
               out = out.invert;
            end
         else
            if isempty(self.Rotation) && isempty(self.Translation)
               out = affine3d;
            else
               [rot, trans] = deal(zeros(1, 3));
               if ~isempty(self.Rotation)
                  L.warn(['`Rotation` property is ordered by ', ...
                     'dimension not xyz.']);
                  rot = self.Rotation;
                  if strcmpi(self.RotationUnits, 'rad')
                     rot = rad2deg(rot);
                  end
               end
               if ~isempty(self.Translation)
                  L.warn(['`Translation` property is ordered by ', ...
                     'dimension not xyz.']);
                  trans = self.Translation;
               end
               out = utils.df2tform(rot, trans, self.DoReverse);
            end
         end
      end
      
      function emptyObj = emptyFun(~, varargin)
         emptyObj = utils.Transform.empty(varargin{:});
      end
      
      function out = get.IsTrivial(self)
         out = isequal(self.T, eye(4));
      end
      
      function out = get.T(self)
         out = self.Affine3D.T;
      end
      
      function set.T(self, val)
         try
            affObj = affine3d(val);
         catch
            affObj = utils.standard2matlabAffine(val);
         end
         self.Affine3D = affObj;
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
         out = self;
         out.Affine3D = affine3d(out.T * obj.T);
      end      
   end
   
   methods (Static)
      function outObj = copyObject(inObj, outObj)
         mc = metaclass(inObj);
         props = mc.Properties;
         for iProp = 1:length(props)
            if ~props{iProp}.Dependent
               outObj.(props{iProp}.Name) = inObj.(props{iProp}.Name);
            end
         end
      end
   end
end


