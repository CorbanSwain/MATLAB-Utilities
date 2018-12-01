classdef TextPlot < utils.PlotBuilder
  
   properties
      X
      Y
      Text
   end
   
   properties (Constant)
     ShadowClass = 'matlab.graphics.primitive.Text'
     ShadowClassTag = ''
     ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)
         self.PlotHandle = text(axisHandle, self.X, self.Y, self.Text);
         self.applyShadowClassProps;         
      end
   end
   
end