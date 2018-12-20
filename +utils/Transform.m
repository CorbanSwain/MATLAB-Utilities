classdef Transform < handle
   properties
      Rotation {mustBeNumeric}
      Translation {mustBeNumeric}
      ZFactor {mustBeNumeric}
      DoReverse (1, 1) logical = false
      InputView imref3d
      OutputView imref3d
      MutualView imref3d
      
      % RotationUnits
      % char
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
      zFactor
      rotation
      translation
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
                     self = utils.Transform.empty;
                     return
                  elseif length(sz) == 1
                     sz = {sz, sz};
                  else                     
                     sz = num2cell(sz);
                  end
               else
                  sz = varargin;
               end
               self(sz{:}) = utils.Transform;
               
            case 'affineObject'
               assert(length(varargin) == 1, ['Only one scalar (or ', ...
                  'array) of affine transform objects can be passed to ', ...
                  'initialize a Transform object.']);
               affObj = varargin{1};
               self = utils.Transform(size(affObj));
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
               self = varargin{1};
            
            otherwise
               error('Unexpected input');
         end
      end
      
      function outPoints = apply(self, points)
         if ~self.DoReverse
            outPoints = self.Affine3D.transformPointsForward(points);
         else
            outPoints = self.Affine3D.transformPointsInverse(points);
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
         else
            if isempty(self.Rotation) && isempty(self.Translation)
               out = affine3d;
            else
               [rot, trans] = deal(zeros(1, 3));
               if ~isempty(self.Rotation)
                  rot = self.Rotation;
                  if strcmpi(self.RotationUnits, 'rad')
                     rot = rad2deg(rot);
                  end
               end
               if ~isempty(self.Translation)
                  trans = self.Translation;
               end
               out = utils.df2tform(rot, trans, self.DoReverse);
            end
         end
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
      
      function out = get.zFactor(self)
         out = self.ZFactor;
      end
      
      function set.zFactor(self, val)
         self.ZFactor = val;
      end
      
      function out = get.translation(self)
         out = self.Translation;
      end
      
      function set.translation(self, val)
         self.Translation = val;
      end
      
      function out = mtimes(self, obj)
         out = utils.Transform(utils.Transform(self).T ...
            * utils.Transform(obj).T);
      end      
   end
end


