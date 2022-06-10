classdef Transform < matlab.mixin.Copyable
   properties
      Rotation {mustBeNumeric, ...
         csmu.validators.mustBeVector(Rotation, [0, 1, 3])}
      Translation {mustBeNumeric, ...
         csmu.validators.mustBeVector(Translation, [0, 2, 3])}

      % DoReverse
      % this property is deprecated, do not set or use
      DoReverse {csmu.validators.mustBeLogicalScalarOrEmpty} = []
            
      InputView csmu.ImageRef {mustBeScalarOrEmpty}               

      DoUseMutualView (1, 1) {csmu.validators.mustBeLogicalScalar} = false
      OutputMutualViewSelection solver.MutualView {mustBeScalarOrEmpty}

      RotationUnits (1, 1) csmu.RotationUnit = 'degree'
      
      TranslationRotationOrder csmu.IndexOrdering ...
         {csmu.validators.mustBeScalarOrEmpty}
   end
   
   properties (GetAccess = 'protected', SetAccess = 'protected')
      ManualOutputView csmu.ImageRef {mustBeScalarOrEmpty}
   end

   properties (SetAccess=protected)
      MaxMutualView csmu.ImageRef {mustBeScalarOrEmpty}
      MinMutualView csmu.ImageRef {mustBeScalarOrEmpty}
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
      
      function P = warpPoints(self, P, nvArgs)       
         arguments
            self Transform
            P
            nvArgs.DoInverse {csmu.validators.mustBeLogicalScalarOrEmpty} = []
         end

         L = csmu.Logger(strcat('csmu.', mfilename(), '.warpPoints'));

         doInverse = self.determineInverseState(nvArgs.DoInverse, L);

         affineObj = self.computeAffineObject(self, doInverse);
         P = affineObj.transformPointsForward(P);
      end
      
      function [varargout] = warpImage(self, I, nvArgs)
         arguments
            self Transform
            I
            nvArgs.WarpArgs (1, :) cell = {}
            nvArgs.DoInverse {csmu.validators.mustBeLogicalScalarOrEmpty} = []
         end

         L = csmu.Logger(strcat('csmu.', mfilename(), '.warpImage'));
         
         doInverse = self.determineInverseState(nvArgs.DoInverse, L);
         
         warpArgs = nvArgs.WarpArgs;
         warpArgs = [warpArgs, {'DoInverse'}, {doInverse}];

         if doInverse
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
            warpArgs = [warpArgs, {'OutputView'}, {RB}];
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

            [B, RB] = csmu.imwarp(I, RA, self, warpArgs{:});
         end
         
         switch nargout
            case 1
               varargout = {B};
            otherwise
               varargout = {B, RB};
         end
      end
      
      function warpedRef = warpRef(self, imref, nvArgs)
         arguments
            self Transform
            imref
            nvArgs.DoInverse {csmu.validators.mustBeLogicalScalarOrEmpty} = []
         end

         L = csmu.Logger(strcat('csmu.', mfilename(), '.warpRef'));

         doInverse = self.determineInverseState(nvArgs.DoInverse, L);
         
         imref = csmu.ImageRef(imref);       
         newOutLims = cell(1, self.NumDims);
         [newOutLims{:}] = self.computeOutputLimits(...
            'InputsLimits', imref.WorldLimits, ...
            'DoInverse', doInverse);
         
         warpedRef = csmu.ImageRef();
         warpedRef.WorldLimits = newOutLims;
      end

      function [varargout] = outputLimits(self, varargin)
         L = csmu.Logger(strcat('csmu.', mfilename(), '.outputLimits'));
         L.warn(['Do not use `outputLimits` method; use ' ...
            '`computeOutputLimits` instead.']);
         varargout = cell(1, self.NumDims);         
         [varargout{:}] = self.AffineObj.outputLimits(varargin{:});
      end
            
      function [varargout] = computeOutputLimits(self, nvArgs)
         arguments
            self Transform
            nvArgs.DoInverse {csmu.validators.mustBeLogicalScalarOrEmpty} = []
            nvArgs.InputLimits = {}
         end
         
         L = csmu.Logger(strcat('csmu.', mfilename(), '.warpImage'));
         doInverse = self.determineInverseState(nvArgs.DoInverse, L);

         varargout = cell(1, self.NumDims);
         affineObj = self.computeAffineObject('DoInverse', doInverse);
         [varargout{:}] = affineObj.outputLimits(nvArgs.InputLimits{:});
      end

      function P = applyToPoints(self, P, varargin)
         L = csmu.Logger('csmu.Transform.applyToPoints');
         L.warn('Transform.applyToPoints is deprecated, use ''warpPoints''');
         P = self.warpPoints(P, varargin{:});
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

         if numTransforms == 0
            L.error(['This method must be called on a non-empty' ...
               ' csmu.Transform array.']);
         end

         function resetReverseStates(tforms, states)
            [tforms.DoReverse] = states{:};
         end

         % performing check for backwards compatibility; however if the
         % DoReverse property is not used, this check does not need to be
         % performed.
         % TODO - remove in future release
         doReverseState = cell(1, numTransforms);
         [doReverseState{:}] = selfArr.DoReverse;
         if any(cellfun(@(x) ~isempty(x), doReverseState), 'all')
            cleanup = onCleanup(...
               @() resetReverseStates(selfArr, doReverseState));
            [selfArr.DoReverse] = deal(false);
         end

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
         L = csmu.Logger('csmu.', mfilename(), '.get.Inverse');
         L.warn(['Do not use the `Inverse` property']);
         out = csmu.Transform(self.AffineObj.invert);
      end
      
      function out = get.Affine3D(self)
         L = csmu.Logger('csmu.', mfilename(), '.get.Affine3D');
         L.warn(['Do not get the `Affine3d` property instead call' ...
            ' the `computeAffineObject` method.'])
         assert(self.NumDims == 3);
         out = self.AffineObj;
      end
      
      function out = get.Affine2D(self)
         L = csmu.Logger('csmu.', mfilename(), '.get.Affine2D');
         L.warn(['Do not get the `Affine2D` property instead call' ...
            ' the `computeAffineObject` method.'])
         assert(self.NumDims == 2);
         out = self.AffineObj;
      end
         
      function out = get.NumDims(self)
         switch class(self.computeAffineObject())
            case 'affine2d'
               out = 2;
            case 'affine3d'
               out = 3;
         end
      end
      
      function out = get.AffineObj(self)
        L = csmu.Logger('csmu.', mfilename(), '.get.AffineObj');
        L.warn(['Do not get the `AffineObj` property instead call' ...
           ' the `computeAffineObject` method.'])
        out = self.computeAffineObject("DoInverse", self.DoReverse);
      end
      
      function affineObj = computeAffineObject(self, nvArgs)
         arguments
            self csmu.Transform
            nvArgs.DoInverse = false
         end

         csmu.validators.notImplemented(self.DoReverse);

         L = csmu.Logger('csmu.', mfilename(), '.computeAffineObject');
         if ~isempty(self.AffineCache)
            if ~isempty(self.Rotation) || ~isempty(self.Translation)
               L.warn(['Defaulting to use the provided the AffineObj \n', ...
                  'object rather than one constructed from the rotation \n',...
                  'and/or translation vectors. To prevent this warning \n', ...
                  'message set either the AffineObj property or both \n', ...
                  'Rotation and Translation properties to an empty array.']);
            end
            affineObj = self.AffineCache;
            if nvArgs.DoInverse
               affineObj = affineObj.invert;
            end
         else
            if isempty(self.Rotation) && isempty(self.Translation)
               L.warn('Defaulting to return an affine3d object');
               affineObj = affine3d();
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

                  rot = self.RotationUnits.toDegrees(rot);

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
               affineObj = csmu.df2tform(rot, trans, nvArgs.DoInverse);
            end
         end
      end

      function out = get.IsTrivial(self)
         out = isequal(self.T, eye(4));
      end
      
      function out = get.T(self)
         L = csmu.Logger('csmu.', mfilename(), '.get.T');
         L.warn(['Do not use the `T` property instead call' ...
            ' the `computeTransformMatrix` method.']);
         out = self.computeTransformMatrix('DoInverse', self.DoReverse);
      end
      
      function transformMatrix = computeTransformMatrix(self, nvArgs)
         arguments
            self csmu.Transform
            nvArgs.DoInverse {csmu.validators.mustBeLogicalScalar} = false
         end
         
         affineObj = self.computeAffineObject('DoInverse', nvArgs.DoInverse);
         transformMatrix = affineObj.T;
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
      
      function set.DoReverse(self, val)
         L = csmu.Logger('csmu.', mfilename(), '.set.DoReverse');
         L.warn(['Do not set `DoReverse`, instead set as an argument when ' ...
            'calling `warpImage`, `warpPoints`, `computeAffineMatrix` or ' ...
            'other method which requires determining the transform array.']);
         
         self.DoReverse = val;
      end

      function out = get.DoReverse(self)
         L = csmu.Logger('csmu.', mfilename(), '.get.DoReverse');
         L.debug(['Do not use `DoReverse`, instead set as an argument when ' ...
            'calling `warpImage`, `warpPoints`, `computeAffineMatrix` or ' ...
            'other method which requires determining the transform array.']);

         self.DoReverse = val;
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
   
   methods (Access=protected)

      function doInverse = determineInverseState(self, localInverseArg, logger)
         L = logger;
         if isempty(self.DoReverse)
            if isempty(localInverseArg)
               doInverse = false;
            else
               doInverse = localInverseArg;
            end
         else
            L.warn('`DoReverse` property should remain unset.')
            if isempty(localInverseArg)
               L.warn('Using `DoReverse` obj property to control method.')
               doInverse = self.DoReverse;
            else
               L.warn(['Overriding `DoReverse` obj property with method ' ...
                  'argument to control method.'])
               doInverse = localInverseArg;
            end
         end
      end

   end

   methods (Static)
      function clearWarpImage
         T = csmu.Transform();
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


