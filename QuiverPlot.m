classdef QuiverPlot
   
   properties
      X
      Y
      U
      V
   end
   
   properties (Constant)
     PlotClass = 'matlab.graphics.chart.primitive.Quiver';
     PlotClassPropertyTag = '';
   end
   
   methods
      function plotGraphics(self, axisHandle)
         self.PlotHandle = quiver(axisHandle, self.X, self.Y, self.U, self.V);
         self.applyPlotClassProps;         
      end
   end
   
end