classdef ImagePlot < csmu.PlotBuilder
   
   properties
      DoScaled = true
      Colormap
      ColorLimits
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
            csmu.colormap(axisHandle, self.Colormap);
         end  
         self.applyShadowClassProps;
      end
   end
   
   methods (Static)
      function plots = projView(varargin)
         imPlot = csmu.ImagePlot;
         [I, bounds, ~, ad] = csmu.projectionView(varargin{:});
         imPlot.I = I;
         imPlot.AlphaData = ad;
         imPlot.Colormap = 'gray';
         
         labelPlots = csmu.addProjViewLabels(bounds, 'Color', 'w');
         plots = [imPlot, labelPlots];
      end
      
      function fb = makeSaveProjView(V, varargin)
         ip = inputParser;
         ip.addParameter('Name', 'untitled_projection_view');
         ip.addParameter('SaveDirectory', '');
         ip.addParameter('Text', '');
         ip.addParameter('ScaleBar', []);
         ip.addParameter('Colormap', 'gray');
         ip.addParameter('ProjectionViewArgs', {});
         ip.addParameter('DoScaled', true);
         ip.addParameter('CLims', []);
         ip.parse(varargin{:});
         name = ip.Results.Name;
         figureDir = ip.Results.SaveDirectory;
         txt = ip.Results.Text;
         scaleBarSpec = ip.Results.ScaleBar;
         projViewArgs = ip.Results.ProjectionViewArgs;
         cmap = ip.Results.Colormap;
         doScaled = ip.Results.DoScaled;
         cLims = ip.Results.CLims;
         
         Isz = csmu.projectionView(V, projViewArgs{:}, 'SizeOnly', true);
         I = zeros(Isz);
         
         tb = csmu.TextPlot;
         tb.X = Isz(2) - size(V, 3) / 2;
         tb.Y = Isz(1) - size(V, 3) / 2;
         tb.Text = txt;
         tb.FontName = 'Input';
         tb.FontSize = 10;
         tb.Interpreter = 'none';
         tb.VerticalAlignment = 'middle';
         tb.HorizontalAlignment = 'center';
         
         ac = csmu.AxisConfiguration;
         gs = csmu.GridSpec;
         ac.Position = gs(1, 1);
         ac.YDir = 'reverse';
         ac.Visible = false;
         ac.XLim = 'auto';
         ac.YLim = 'auto';
         
         imPlots = csmu.ImagePlot.projView(V, projViewArgs{:});
         imPlots(1).Colormap = cmap;
         imPlots(1).DoScaled = doScaled;
         imPlots(1).ColorLimits = cLims;
         
         fb = csmu.ImagePlot.fullImageFig(I);
         fb.AxisConfigs = ac;
         fb.PlotBuilders = [imPlots, tb];
         fb.Name = name;
         fb.figure;
         fb.save(figureDir);
         %fb.close;
      end
      
      function fb = fullImageFig(I)
          ISize = size(I);
          IAspectRatio = ISize(1) / ISize(2);
          defaultSize = 1000;
          
          axc = csmu.AxisConfiguration;
          axc.XLim = [0.5, 0.5 + ISize(2)];
          axc.YLim = [0.5, 0.5 + ISize(1)];
          axc.YDir = 'reverse';
          axc.Visible = 'off';
          axc.ActivePositionProperty = 'position';
          axc.Units = 'normalized';
          axc.Position = [0 0 1 1];
          axc.DataAspectRatio = [1 1 1];
          axc.DataAspectRatioMode = 'manual';
          
          fb = csmu.FigureBuilder;
          fb.Position = [0, 0, defaultSize, defaultSize * IAspectRatio];
          fb.AxisConfigs = {axc};
      end
   end
   
end