classdef ImagePlot < utils.PlotBuilder
   
   properties
      DoScaled = true
      Colormap
      I
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.primitive.Image'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
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
         self.applyShadowClassProps;
      end
   end
   
   methods (Static)
      function plots = projView(varargin)
         imPlot = utils.ImagePlot;
         [I, bounds, ~, ad] = utils.projectionView(varargin{:});
         imPlot.I = I;
         imPlot.AlphaData = ad;
         imPlot.Colormap = 'gray';
         
         labelPlots = utils.addProjViewLabels(bounds, 'Color', 'w');
         plots = [{imPlot}, labelPlots];
      end
      
      function makeSaveProjView(name, figureDir, V, varargin)
         I = zeros(utils.projectionView(V, 'SizeOnly', true));
         fb = utils.ImagePlot.fullImageFig(I);
         fb.PlotBuilders = {utils.ImagePlot.projView(V, varargin{:})};
         fb.Name = name;
         fb.figure;
         fb.save(figureDir);
         fb.close;
      end
      
      function fb = fullImageFig(I)
          ISize = size(I);
          IAspectRatio = ISize(1) / ISize(2);
          defaultSize = 1000;
          
          axc = utils.AxisConfiguration;
          axc.XLim = [0.5, 0.5 + ISize(2)];
          axc.YLim = [0.5, 0.5 + ISize(1)];
          axc.YDir = 'reverse';
          axc.Visible = 'off';
          axc.ActivePositionProperty = 'position';
          axc.Units = 'normalized';
          axc.Position = [0 0 1 1];
          axc.DataAspectRatio = [1 1 1];
          axc.DataAspectRatioMode = 'manual';
          
          fb = utils.FigureBuilder;
          fb.Position = [0, 0, defaultSize, defaultSize * IAspectRatio];
          fb.AxisConfigs = {axc};
      end
   end
   
end