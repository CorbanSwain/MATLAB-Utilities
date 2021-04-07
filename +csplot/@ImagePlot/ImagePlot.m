classdef ImagePlot < csplot.PlotBuilder
   properties
      DoScaled = true
      Colormap
      ColorLimits
      DoConvertToRGB = false
      I
      X
      Y
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.primitive.Image'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods      
      function plotGraphics(self, axisHandle)
         args = {axisHandle};         
         if ~isempty(self.X) && ~isempty(self.Y)
            args = [args, {'XData', self.X, 'YData', self.Y}];
         end
         
         image = csmu.Image(self.I);
         imData = image.I;
         
         if self.DoConvertToRGB && ~isempty(self.Colormap)
            rgbImage = csplot.gray2rgb(imData, self.Colormap, ...
               'ColorLimits', self.ColorLimits, 'DoScaled', self.DoScaled);
            args = [args, {'CData', rgbImage}];
            self.PlotHandle = builtin('image', args{:});
         else
            if ~isempty(imData)
               args = [args, {'CData', imData}];
            end
            
            if self.DoScaled
               if ~isempty(self.ColorLimits)
                  args = [args, {self.ColorLimits}];
               end
               self.PlotHandle = imagesc(args{:});
            else
               self.PlotHandle = builtin('image', args{:});
               if ~isempty(self.ColorLimits)
                  axisHandle.CLim = self.ColorLimits;
               end
            end
            
            if ~isempty(self.Colormap)
               csplot.colormap(axisHandle, self.Colormap);
            end
         end
         self.applyShadowClassProps;
      end     
   end
   
   methods (Static) 
      
      fb = projView(V, varargin)
      plots = projViewOld(varargin)
      fb = makeSaveProjeViewOld(V, varargin);
      fb = fullImageFig(I)      
   end
   
end