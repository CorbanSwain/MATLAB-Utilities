classdef QuiverPlot < csmu.PlotBuilder
   
   properties
      X
      Y
      Z
      U
      V
      W
   end
   
   properties (Constant)
     ShadowClass = 'matlab.graphics.chart.primitive.Quiver'        
     ShadowClassTag = ''
     ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)
         if isempty(self.Z) || isempty(self.W)
            self.PlotHandle = quiver(axisHandle, ...
               self.X, self.Y, ...
               self.U, self.V);
         else
            self.PlotHandle = quiver3(axisHandle, ...
               self.X, self.Y, self.Z, ...
               self.U, self.V, self.W);
         end
         self.applyShadowClassProps;         
      end
   end
   
end