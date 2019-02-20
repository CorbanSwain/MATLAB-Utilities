classdef ImagePlot < csmu.PlotBuilder
   
   properties
      DoScaled = true
      Colormap
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
            self.PlotHandle = imagesc(args{:});
         else
            self.PlotHandle = image(args{:});
         end
         
         if ~isempty(self.Colormap)
            colormap(axisHandle, self.Colormap);
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
         ip.addParameter('ProjectionViewArgs', {});
         ip.parse(varargin{:});
         name = ip.Results.Name;
         figureDir = ip.Results.SaveDirectory;
         txt = ip.Results.Text;
         scaleBarSpec = ip.Results.ScaleBar;
         projViewArgs = ip.Results.ProjectionViewArgs;
         
         Isz = csmu.projectionView(V, projViewArgs{:}, 'SizeOnly', true);
         I = zeros(Isz);
         
         tb = csmu.TextPlot;
         tb.X = Isz(2) - size(V, 3) / 2;
         tb.Y = Isz(1) - size(V, 3) / 2;
         tb.Text = txt;
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
         
         fb = csmu.ImagePlot.fullImageFig(I);
         fb.AxisConfigs = ac;
         fb.PlotBuilders = [csmu.ImagePlot.projView(V, projViewArgs{:}), ...
            tb];
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