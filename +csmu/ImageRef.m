classdef ImageRef < csmu.Object
   properties
      Ref     
   end
   
   properties (Dependent)
      NumDims
      
      WorldLimits
      
      PixelCenterLimits
      XPixelCenterLimits
      YPixelCenterLimits
      ZPixelCenterLimits
      
      % shadows of imref2d/3d
      XWorldLimits
      YWorldLimits
      ZWorldLimits
      
      ImageSize    
      
      PixelExtentInWorldX
      PixelExtentInWorldY
      PixelExtentInWorldZ      
                  
      ImageExtentInWorldX
      ImageExtentInWorldY
      ImageExtentInWorldZ  
      
      XIntrinsicLimits
      YIntrinsicLimits
      ZIntrinsicLimits            
   end
   
   properties (Constant, Hidden = true)
      ImRefClassNames = {'imref2d', 'imref3d'}
   end
   
   methods
      function self = ImageRef(varargin)
         if nargin            
            switch class(varargin{1})
               case self.ImRefClassNames
                  % A matlab imref2d or imref3d object is passed.
                  narginchk(1, 1);
                  self.Ref = varargin{1};
                  
               case 'csmu.ImageRef'
                  % A csmu.ImageRef object is passed.
                  narginchk(1, 1);
                  self = copy(varargin{1});
                  
               case 'csmu.Image'
                  % A csmu.Image object is passed.
                  self = csmu.ImageRef(varargin{1}.I);
                  
               otherwise
                  assert(isnumeric(varargin{1}), 'Unexpected input provided.');
                  if isvector(varargin{1})
                     % A valid argument to either imref2d or imref3d is
                     % passed.
                     self.Ref = self.makeMatlabImRef(varargin{:});
                  else
                     % An image (2D or 3D) is passed, only need the size.
                     narginchk(1, 1);
                     nDim = ndims(varargin{1});
                     assert(any(nDim == [2, 3]), ...
                        'Image-like input must have either 2 or 3 dimensions');
                     self.Ref = self.makeMatlabImRef(size(varargin{1}));
                  end
            end
         end
      end
      
      function transform(self, tform)
         tform = csmu.Transform(tform);
         self.Ref = tform.warpRef(self);
      end
      
      function set.Ref(self, val)
         switch class(val)
            case self.ImRefClassNames
               self.Ref = val;
               
            case 'csmu.ImageRef'
               self.Ref = val.Ref;
               
            otherwise
               error('Unexpected value set to `Ref`');
         end
      end
      
      function out = get.XPixelCenterLimits(self)
         out = self.XWorldLimits + ([1, -1] * (self.PixelExtentInWorldX / 2));
      end
      
      function out = get.YPixelCenterLimits(self)
         out = self.YWorldLimits + ([1, -1] * (self.PixelExtentInWorldY / 2));
      end
      
      function out = get.ZPixelCenterLimits(self)
         if self.NumDims == 2
            error('A 2d image ref has no property ''ZPixelCenterLimits''');
         else
            out = self.ZWorldLimits ...
               + ([1, -1] * (self.PixelExtentInWorldZ / 2));
         end
      end
      
      function out = get.XWorldLimits(self)
         out = self.Ref.XWorldLimits;
      end
      
      function out = get.YWorldLimits(self)
         out = self.Ref.YWorldLimits;
      end
      
      function out = get.ZWorldLimits(self)
         if self.NumDims == 2
            error('A 2d image ref has no property ''ZWorldLimits''');
         else
            out = self.Ref.ZWorldLimits;
         end
      end
      
      function out = get.NumDims(self)
         switch class(self.Ref)
            case 'imref2d'
               out = 2;
            case 'imref3d'
               out = 3;
         end
      end
      
      function out = get.WorldLimits(self)
         out = {self.Ref.XWorldLimits, self.Ref.YWorldLimits};
         if self.NumDims == 3
            out = [out, {self.ZWorldLimits}];            
         end
      end
      
      function out = get.PixelCenterLimits(self)
         out = {self.XPixelCenterLimits, self.YPixelCenterLimits};
         if self.NumDims == 3
            out = [out, {self.ZPixelCenterLimits}];            
         end
      end
      
      function set.WorldLimits(self, val)
         imSize = self.lims2size(val);
         function newLims = convertLims(dimSz, lims)
            newLims = mean(lims) + (dimSz / 2 * [-1 1]);
         end         
         properLimits = csmu.cellmap(@(l, s) convertLims(s, l), val, ...
            num2cell(imSize([2 1 3])));
         self.Ref = csmu.ImageRef(imSize, properLimits{:});
      end
      
      function out = get.YIntrinsicLimits(self)
         out = self.Ref.YIntrinsicLimits;
      end   
      
      function out = get.XIntrinsicLimits(self)
         out = self.Ref.XIntrinsicLimits;
      end   
      
      function out = get.PixelExtentInWorldZ(self)
         if self.NumDims == 2
            error('A 2d image ref has no property ''PixelExtentInWorldZ''');
         else
            out = self.Ref.PixelExtentInWorldZ;
         end         
      end      
      
      function out = get.ImageExtentInWorldX(self)
         out = self.Ref.ImageExtentInWorldX;
      end      
      
      function out = get.ImageExtentInWorldY(self)
         out = self.Ref.ImageExtentInWorldY;
      end      
      
      function out = get.ImageExtentInWorldZ(self)
         if self.NumDims == 2
            error('A 2d image ref has no property ''ImageExtentInWorldZ''');
         else
            out = self.Ref.ImageExtentInWorldZ;
         end
      end      
      
      function out = get.PixelExtentInWorldX(self)
         out = self.Ref.PixelExtentInWorldX;
      end      
      
      function out = get.PixelExtentInWorldY(self)
         out = self.Ref.PixelExtentInWorldY;
      end      
      
      function out = get.ZIntrinsicLimits(self)
         if self.NumDims == 2
            error('A 2d image ref has no property ''ZIntrinsicLimits''');
         else
            out = self.Ref.ZIntrinsicLimits;
         end         
      end   
      
      function out = get.ImageSize(self)
         out = self.Ref.ImageSize;
      end
      
      function zeroCenter(self)
         limFun = @(x) [-1 1] * x / 2;
         self.WorldLimits = arrayfun(limFun, self.ImageSize, ...
            'UniformOutput', false);         
      end
         
   end
   
   methods (Static)
      function sz = lims2size(limits)
         limits = cat(1, limits{:});
         sz = round(diff(limits, 1, 2))';
         sz([1, 2]) = sz([2, 1]);
      end  
      
      function ref = makeMatlabImRef(varargin)
         nDim = length(varargin{1});
         if nDim == 2
            ref = imref2d(varargin{:});
         elseif nDim == 3
            ref = imref3d(varargin{:});
         else
            error('Unexpected input provided.');
         end
      end
   end
   
end