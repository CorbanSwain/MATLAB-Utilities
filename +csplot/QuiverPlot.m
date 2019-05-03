classdef QuiverPlot < csplot.PlotBuilder
   
   properties
      X
      Y
      U
      V
   end
   
   properties (Constant)
     ShadowClass = 'matlab.graphics.chart.primitive.Quiver'
     ShadowClassTag = ''
     ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)
         self.PlotHandle = quiver(axisHandle, self.X, self.Y, self.U, self.V);
         self.applyShadowClassProps;         
      end
   end
   
end