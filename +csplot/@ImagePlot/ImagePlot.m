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
         
         if self.DoConvertToRGB && ~isempty(self.Colormap)
            cmap = csplot.colormap(self.Colormap);
            numColors = size(cmap, 1);
            indexImage = self.I;
            if ~isempty(self.ColorLimits)
               if ~isfloat(indexImage)
                  indexImage = double(indexImage);
               end
               indexImage = (indexImage - self.ColorLimits(1)) ...
                  / diff(self.ColorLimits);
            elseif self.DoScaled
               indexImage = csmu.fullscaleim(indexImage);
            end
            indexImage = round((indexImage * (numColors - 1)) + 1);
            rgbImage = ind2rgb(indexImage, cmap);
            args = [args, {'CData', rgbImage}];
            self.PlotHandle = image(args{:});
         else
            if ~isempty(self.I)
               args = [args, {'CData', self.I}];
            end
            
            if self.DoScaled
               if ~isempty(self.ColorLimits)
                  args = [args, {self.ColorLimits}];
               end
               self.PlotHandle = imagesc(args{:});
            else
               self.PlotHandle = image(args{:});
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