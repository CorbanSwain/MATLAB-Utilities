classdef Transform < matlab.mixin.Copyable
   properties
      Rotation {mustBeNumeric, ...
         csmu.validators.mustBeVector(Rotation, [0, 1, 3])}
      Translation {mustBeNumeric, ...
         csmu.validators.mustBeVector(Translation, [0, 2, 3])}
      DoReverse (1, 1) logical = false
      InputView csmu.ImageRef {mustBeScalarOrEmpty}     
      
      MaxMutualView csmu.ImageRef {mustBeScalarOrEmpty}
      MinMutualView csmu.ImageRef {mustBeScalarOrEmpty}

      DoUseMutualView (1, 1) logical = false
      OutputMutualViewSelection solver.MutualView {mustBeScalarOrEmpty}

      % RotationUnits
      % char (default is 'deg')
      %
      % either 'deg' or 'rad'
      RotationUnits (1, :) char ...
         {csmu.validators.mustBeValidRotationUnit} = 'deg'
      
      TranslationRotationOrder csmu.IndexOrdering ...
         {csmu.validators.mustBeScalarOrEmpty}
   end
   
   properties (GetAccess = 'protected', SetAccess = 'protected')
      ManualOutputView csmu.ImageRef {mustBeScalarOrEmpty}
   end

   properties (GetAccess = 'private', SetAccess = 'private')
      AffineCache
   end
   
   properties (Dependent)
      OutputView

      AffineObj
      Affine2D
      Affine3D
      T
      IsTrivial
      Inverse
      NumDims
      DoInverse
      
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
         
         % parse inputs
         ip = inputParser;
         ip.addParameter('WarpArgs', {}, @(x) iscell(x));       
         warpParams = ip.Results.WarpArgs;
         
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

            [B, RB] = csmu.imwarp(I, RA, self, warpParams{:});
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
         
      function computeMutualViews(selfArr)
         funcName = strcat('csmu.', mfilename(), '.computeMutualViews');
         L = csmu.Logger(funcName);

         numTransforms = length(selfArr);
         
         function resetReverseStates(tforms, states)
            [tforms.DoReverse] = states{:};
         end

         if numTransforms == 0
            L.error(['This method must be called on a non-empty' ...
               ' csmu.Transform array.']);
         elseif numTransforms == 1
            minMutualView =selfArr.OutputView;
            maxMutualView = selfArr.OutputView;
         else
            doReverseState = cell(1, numTransforms);
            [doReverseState{:}] = selfArr.DoReverse;
            cleanup = onCleanup(...
               @() resetReverseStates(selfArr, doReverseState));
            [selfArr.DoReverse] = deal(false);

            outputRefs = arrayfun(@(t) t.warpRef(t.InputView), selfArr);
           
            clear('cleanup');

            outputWorldLimits = cell(1, numTransforms);
            [outputWorldLimits{:}] = outputRefs.WorldLimits;            

            outputWorldLimits_matrix = csmu.cellmap(...
               @(c) cat(1, c{:}), outputWorldLimits);
            worldLimitsRange = cat(3, outputWorldLimits_matrix{:});

            maxMutualWorldLimits = [
               min(worldLimitsRange(:, 1, :), [], 3), ...
               max(worldLimitsRange(:, 2, :), [], 3)];

            minMutualWorldLimits =  [
               max(worldLimitsRange(:, 1, :), [], 3), ...
               min(worldLimitsRange(:, 2, :), [], 3)];

            maxMutualView = csmu.ImageRef.fromWorldLimits(maxMutualWorldLimits);
            minMutualView = csmu.ImageRef.fromWorldLimits(minMutualWorldLimits);
         end

         [selfArr.MinMutualView] = deal(minMutualView);
         [selfArr.MaxMutualView] = deal(maxMutualView);
      end
      

      function clearOutputView(self)
         self.ManualOutputView = [];
      end

      function clearMutualViews(self)
         self.MinMutualView = [];
         self.MaxMutualView = [];
      end

      function emptyObj = emptyFun(~, varargin)
         emptyObj = csmu.Transform.empty(varargin{:});
      end

      %% Get-Set Methods
      function out = get.OutputView(self)
         L = csmu.Logger('csmu.', mfilename(), 'get.OutputView');

         if self.DoUseMutualView
            switch self.OutputMutualViewSelection
               case solver.MutualView.MIN_VIEW
                  out = self.MinMutualView;
               case solver.MutualView.MAX_VIEW
                  out = self.MaxMutualView;
               otherwise
                  L.error(['OutputMutualViewSelection property must be set ' ...
                     'if DoUseMutualView is true.'])
            end

            if isempty(out)              
               L.warn('Mutual views have not been calculated/set.');
            end
         else
            out = self.ManualOutputView;
         end
      end

      function set.OutputView(self, x)
         if self.DoUseMutualView
            L = csmu.Logger('csmu.', mfilename(), 'set.OutputView');
            L.error(['OutputView cannot be set if using mutual views, set' ...
               'DoUseMutualView property to false before setting.']);
         else
            self.ManualOutputView = x;
         end
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
      
      function out = get.DoInverse(self)
         out = self.DoReverse;
      end

      function set.DoInverse(self, val)
         self.DoReverse = val;
      end

      function out = mtimes(self, obj)
         out = csmu.Transform();
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


