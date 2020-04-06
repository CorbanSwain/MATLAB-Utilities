classdef PlotBuilder < csmu.DynamicShadowOld & matlab.mixin.Heterogeneous
   
   methods (Abstract)
      plotGraphics(self, axisHandle)
   end
   
   properties (NonCopyable)
      PlotHandle
   end
   
   properties (Hidden = true)
      PropertySetList = {}
   end
   
   methods                 
      function plot(self, axisHandle)
         self.plotGraphics(axisHandle);
      end            
      
      function applyShadowClassProps(self, varargin)
         ip = inputParser;
         ip.addOptional('ObjectHandle', self.PlotHandle);
         ip.parse(varargin{:});
         objectHandle = ip.Results.ObjectHandle;
         self.PropsToSet = self.PropertySetList;
         applyShadowClassProps@csmu.DynamicShadowOld(self, objectHandle);
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
         defaultObject = csmu.DefaultPlotBuilder;
      end
   end
   
end