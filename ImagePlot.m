classdef ImagePlot < utils.PlotBuilder
   
   properties
      DoScaled = true
      Colormap
      I
   end
   
   properties (Constant)
      PlotClass = 'matlab.graphics.primitive.Image';
      PlotClassPropertyTag = '';
   end
   
   methods
      
      function plotGraphics(self, axisHandle)
         if self.DoScaled
            self.PlotHandle = imagesc(axisHandle, self.I);
         else
            self.PlotHandle = image(axisHandle, self.I);
         end
         if ~isempty(self.Colormap)
            colormap(axisHandle, self.Colormap);
         end  
         self.applyPlotClassProps;
      end
   end
end