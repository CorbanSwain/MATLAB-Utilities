classdef PlotBuilder < csmu.mixin.DynamicShadow & csmu.mixin.AutoDeal
   
   methods (Abstract)
      plotGraphics(self, axisHandle)
   end
   
   properties (NonCopyable)
      PlotHandle
   end
   
   properties (Constant)
      DoCopyOnAutoDeal = true
   end
   
   methods      
      function self = PlotBuilder(varargin)
         if nargin
            sizeCell = csmu.parseSizeArgs(varargin{:});
            % FIXME - need to handle empty arrays
            self(sizeCell{:}) = self;
            for iAc = 1:numel(self)
               self(iAc) = copy(self(sizeCell{:}));
            end
         end
      end
      
      function plot(self, axisHandle)
         self.plotGraphics(axisHandle);
      end            
      
      function applyShadowClassProps(self, varargin)
         ip = inputParser;
         ip.addOptional('ObjectHandle', self.PlotHandle);
         ip.parse(varargin{:});
         objectHandle = ip.Results.ObjectHandle;
         applyShadowClassProps@csmu.mixin.DynamicShadow(self, objectHandle);
      end      
      
      function out = getGObjectFcn(self, idx)
         if nargin == 1
            idx = 1;
         end
         out = @() self.PlotHandle(idx);
      end
   end
   
   methods (Static, Sealed, Access = protected)
      function defaultObject = getDefaultScalarElement
         defaultObject = csplot.DefaultPlotBuilder;
      end
   end
   
end