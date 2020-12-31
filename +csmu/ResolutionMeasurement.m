classdef ResolutionMeasurement < csmu.Object
   properties
      ImageRef csmu.ImageRef
      Position
      IntensityLines
      PeakValid
      PeakPosition
      PeakEdgeValue
      PeakProminance
      PeakValue
      PeakBackground
      PeakEdges
      Index
      Image
   end
   
   properties (Dependent)
      PeakWidth
   end
   
   methods
      
      function val = get.PeakWidth(self)
         val = cellfun(@diff, self.PeakEdges);
      end
      
%       function val = get.XHalfMaxPoints(self)
%          [xLine, yLine, zLine] = self.IntensityLines{:};
%          [xPeak, yPeak, zPeak] = csmu.cell2csl(num2cell(self.PeakValue));
%          [xWidth, yWidth, zWidth] = csmu.cell2csl(num2cell(self.PeakWidth));
%          [xLoc, yLoc, zLoc] = csmu.cell2csl(num2cell(self.PeakPosition));
%          
%          peak = xPeak;
%          loc = xLoc;
%          intensity = xLine;
%          width = xWidth;
%          
%          
%          val = self.edgeHelper(intensity, width, peak, loc);
%       end
%       
%       function val = get.YHalfMaxPoints(self)
%          [xLine, yLine, zLine] = self.IntensityLines{:};
%          [xPeak, yPeak, zPeak] = csmu.cell2csl(num2cell(self.PeakValue));
%          [xWidth, yWidth, zWidth] = csmu.cell2csl(num2cell(self.PeakWidth));
%          [xLoc, yLoc, zLoc] = csmu.cell2csl(num2cell(self.PeakPosition));
%          
%          peak = yPeak;
%          loc = yLoc;
%          intensity = yLine;
%          width = yWidth;
%          
%          val = self.edgeHelper(intensity, width, peak, loc);
%       end
%       
%       function val = get.ZHalfMaxPoints(self)
%          [xLine, yLine, zLine] = self.IntensityLines{:};
%          [xPeak, yPeak, zPeak] = csmu.cell2csl(num2cell(self.PeakValue));
%          [xWidth, yWidth, zWidth] = csmu.cell2csl(num2cell(self.PeakWidth));
%          [xLoc, yLoc, zLoc] = csmu.cell2csl(num2cell(self.PeakPosition));
%          
%          peak = zPeak;
%          loc = zLoc;
%          intensity = zLine;
%          width = zWidth;
%          
%          val = self.edgeHelper(intensity, width, peak, loc);
%       end
      
      function fb = figure(self, varargin)
         L = csmu.Logger(mfilename);
         
         %% Parsing Inputs
         ip = inputParser;
         ip.addOptional('Image', self.Image);
         ip.addParameter('AnnotationText', '');
         ip.addParameter('DoShowHeightAxis', false);
         ip.addParameter('DoMaxProjection', false);
         ip.addParameter('ViewWidth', []);
         ip.addParameter('Colormap', 'gray');
         ip.parse(varargin{:});
         V = ip.Results.Image;
         annotationText = ip.Results.AnnotationText;
         doMaxProjection = ip.Results.DoMaxProjection;
         doShowHeightAxis = ip.Results.DoShowHeightAxis;
         cmap = ip.Results.Colormap;
         viewWidth = ip.Results.ViewWidth;
         
         %% Constants
         defaultViewWidth = 250;
         
         %% Assigning variables ...
         %%% ... from ResMeasure object
         point = self.Position;
         [xLine, yLine, zLine] = self.IntensityLines{:};
         [xPeak, yPeak, zPeak] = csmu.cell2csl(num2cell(self.PeakValue));
         [xWidth, yWidth, zWidth] = csmu.cell2csl(num2cell(self.PeakWidth));
         [xLoc, yLoc, zLoc] = csmu.cell2csl(num2cell(self.PeakPosition));
         
         %%% ... from volume
         volSize = size(V);
         
         %% Generating View
         %%% View Width
         if isempty(viewWidth)
            viewWidth = min(defaultViewWidth, max(volSize));
         end
         xlim = point(1) + ([-1 1] * viewWidth / 2);
         ylim = point(2) + ([-1 1] * viewWidth / 2);
         zlim = point(3) + ([-1 1] * viewWidth / 2);
         
         %%% Window Selections
         xzWindow = {max(round(zlim(1)), 1):min(round(zlim(2)), volSize(3)), ...
            max(round(xlim(1)), 1):min(round(xlim(2)), volSize(2))};
         yzWindow = {max(round(zlim(1)), 1):min(round(zlim(2)), volSize(3)), ...
            max(round(ylim(1)), 1):min(round(ylim(2)), volSize(1))};
         
         %%% Projections / Slices
         L.info('\tGenerating Max Projections');
         if doMaxProjection
            xz = permute(csmu.maxProject(V, 1), [2 1]);
            yz = permute(csmu.maxProject(V, 2), [2 1]);
         else
            ySlice = [floor(point(2)), ceil(point(2))];
            xSlice = [floor(point(1)), ceil(point(1))];
            yMultiplier = abs(ySlice([2, 1]) - point(2));
            xMultiplier = abs(xSlice([2, 1]) - point(1));
            if sum(yMultiplier) < (1 - eps)
               yMultiplier = [1, 0];
            end
            if sum(xMultiplier) < (1 - eps)
               xMultiplier = [1 0];
            end
            xz = V(ySlice(1), :, :) * yMultiplier(1) ...
               + V(ySlice(2), :, :) * yMultiplier(2);
            xz = permute(squeeze(xz), [2 1]);
            yz = V(:, xSlice(1), :) * xMultiplier(1) ...
               + V(:, xSlice(2), :) * xMultiplier(2);
            yz = permute(squeeze(yz), [2 1]);
         end
         
         %%% Window Scale
         xzWindowed = xz(xzWindow{:});
         xzScale = [min(xzWindowed(:)), max(xzWindowed(:))];
         
         yzWindowed = yz(yzWindow{:});
         yzScale = [min(yzWindowed(:)), max(yzWindowed(:))];
         
         %% Plotting
         L.info('\tGenerating Plot');
         csmu.FigureBuilder.setDefaults;
         imPlots = csmu.plotBuilders(1, 2);
         imPlots(1) = csmu.ImagePlot;
         imPlots(1).Colormap = cmap;
         for iPlot = 2:length(imPlots)
            imPlots(iPlot) = copy(imPlots(1));
         end
         imPlots(1).I = xz;
         imPlots(1).ColorLimits = xzScale;
         imPlots(2).I = yz;
         imPlots(2).ColorLimits = yzScale;
         
         linePlots = csmu.plotBuilders(1, 3);
         linePlots(1) = csmu.LinePlot;
         linePlots(1).LineSpec = {'-r'};
         linePlots(1).LineWidth = 1.5;
         for iPlot = 2:length(linePlots)
            linePlots(iPlot) = copy(linePlots(1));
         end
         linePlots(1).X = 1:length(xLine);
         linePlots(1).Y = xLine;
         linePlots(2).X = 1:length(yLine);
         linePlots(2).Y = yLine;
         linePlots(3).X = zLine;
         linePlots(3).Y = 1:length(zLine);
         
         imLinePlots = csmu.plotBuilders(1, 4);
         imLinePlots(1) = csmu.LinePlot;
         imLinePlots(1).LineSpec = {':r'};
         imLinePlots(1).LineWidth = 0.7;
         for iPlot = 2:length(imLinePlots)
            imLinePlots(iPlot) = copy(imLinePlots(1));
         end
         imLinePlots(1).X = [0.5, volSize(1) + 0.5];
         imLinePlots(1).Y = ones(1, 2) * point(3);
         imLinePlots(2).X = ones(1, 2) * point(1);
         imLinePlots(2).Y = [0.5, volSize(3) + 0.5];
         imLinePlots(3).X = [0.5, volSize(1) + 0.5];
         imLinePlots(3).Y = ones(1, 2) * point(3);
         imLinePlots(4).X = ones(1, 2) * point(2);
         imLinePlots(4).Y = [0.5, volSize(2) + 0.5];
         
         pointPlots = csmu.plotBuilders(1, 3);
         pointPlots(1) = csmu.ScatterPlot;
         pointPlots(1).Marker = 'v';
         pointPlots(1).MarkerEdgeColor = 'none';
         pointPlots(1).MarkerFaceColor = 'r';
         pointPlots(1).LineWidth = 1.5;
         for iPlot = 2:length(pointPlots)
            pointPlots(iPlot) = copy(pointPlots(1));
         end
         pointPlots(1).X = xLoc;
         pointPlots(1).Y = xPeak;
         pointPlots(2).X = yLoc;
         pointPlots(2).Y = yPeak;
         pointPlots(3).Marker = '>';
         pointPlots(3).X = zPeak;
         pointPlots(3).Y = zLoc;
         
         texts = csmu.plotBuilders(1, 4);
         texts(1) = csmu.TextPlot;
         texts(1).Position = [0 1];
         texts(1).Units = 'normalized';
         texts(1).FontName = 'Input';
         texts(1).FontSize = 12 ;
         texts(1).VerticalAlignment = 'top';
         for iPlot = 2:length(texts)
            texts(iPlot) = copy(texts(1));
         end
         texts(1).Text = sprintf('FWHM, X = %.2f um', xWidth / 2);
         texts(2).Text = sprintf('FWHM, Y = %.2f um', yWidth / 2);
         texts(3).Text = sprintf('FWHM, Z\n  = %.2f um', zWidth / 2);
         texts(4).Interpreter = 'none';
         texts(4).FontSize = 9;
         texts(4).Text = annotationText;
         
         gs = csmu.GridSpec(3, 5);
         gs.VSpace = 0.35;
         gs.HSpace = 0.35;
         axisConfigs(1, 6) = csmu.AxisConfiguration;
         axisConfigs(1).TickDir = 'out';
         for iAc = 2:length(axisConfigs)
            axisConfigs(iAc) = copy(axisConfigs(1));
         end
         
         if doShowHeightAxis
            axisConfigs(1).YTick = [0 ceil(max(xLine))];
            axisConfigs(2).YTick = [0 ceil(max(yLine))];
            axisConfigs(1).YAxisLocation = 'right';
            axisConfigs(2).YAxisLocation = 'right';
            axisConfigs(3).XTick = [0 ceil(max(zLine))];
         else
            axisConfigs(1).YAxis.Visible = 'off';
            axisConfigs(2).YAxis.Visible = 'off';
            axisConfigs(3).XAxis.Visible = 'off';
         end
         
         axisConfigs(1).Position = gs(1, 2:3);
         
         axisConfigs(1).XLim = xlim;
         axisConfigs(1).XLabel = 'X (voxels)';
         axisConfigs(1).YLim = [-(max(xLine) * 0.01), ceil(max(xLine))];
         axisConfigs(2).Position = gs(1, 4:5);
         
         axisConfigs(2).XLim = ylim;
         axisConfigs(2).XLabel = 'Y (voxels)';
         axisConfigs(2).YLim = [-(max(yLine) * 0.01), ceil(max(yLine))];
         axisConfigs(3).Position = gs(2:3, 1);
         
         axisConfigs(3).YAxis.Visible = 'on';
         axisConfigs(3).YAxisLocation = 'right';
         axisConfigs(3).XDir = 'reverse';
         axisConfigs(3).YLim = zlim;
         axisConfigs(3).XLim = [-(max(zLine) * 0.05), ceil(max(zLine))];
         axisConfigs(3).YLabel = 'Z (voxels)';
         for iAc = 4:6
            axisConfigs(iAc).Visible = 'off';
         end
         axisConfigs(4).Position = gs(2:3, 2:3);
         axisConfigs(4).XLim = xlim;
         axisConfigs(4).YLim = zlim;
         axisConfigs(5).Position = gs(2:3, 4:5);
         axisConfigs(5).XLim = ylim;
         axisConfigs(5).YLim = zlim;
         axisConfigs(6).Position = gs(1, 1);
         
         fb = csmu.FigureBuilder;
         fb.DoUseSubplot = false;
         fb.PlotBuilders = {[linePlots(1), pointPlots(1), texts(1)], ...
            [linePlots(2), pointPlots(2), texts(2)], ...
            [linePlots(3), pointPlots(3), texts(3)], ...
            [imPlots(1), imLinePlots(1:2)], ...
            [imPlots(2), imLinePlots(3:4)], ...
            texts(4)};
         fb.AxisConfigs = axisConfigs;
         figHeight = 800;
         fb.Position = [908, 250, (gs.FigureAspectRatio * figHeight), ...
            figHeight];
         fb.LinkAxes = {[1 4], 'x'; [2 5], 'x'; [3 4 5], 'y'};
      end
      
      function fb = prettyFigure(self, varargin)
         L = csmu.Logger(mfilename);
         
         %% Parsing Inputs
         ip = inputParser;
         ip.addOptional('Image', self.Image);
         ip.addParameter('AnnotationText', '');
         ip.addParameter('DoShowHeightAxis', false);
         ip.addParameter('DoShowPeakMarker', true);
         ip.addParameter('DoShowMeasurementText', true);
         ip.addParameter('DoMaxProjection', false);
         ip.addParameter('ViewWidth', []);
         ip.addParameter('Colormap', 'magma');
         ip.addParameter('DoDarkMode', false);
         ip.addParameter('FontName', 'Helvetica');
         ip.parse(varargin{:});
         V = ip.Results.Image;
         inputs = ip.Results;
         annotationText = ip.Results.AnnotationText;
         doMaxProjection = ip.Results.DoMaxProjection;
         doShowHeightAxis = ip.Results.DoShowHeightAxis;
         cmap = ip.Results.Colormap;
         viewWidth = ip.Results.ViewWidth;
         
         %% Constants
         defaultViewWidth = 250;
         lightGrey = ones(1, 3) * 225 / 255;
         darkGrey = ones(1, 3) * 25 / 255;
         
         %% Assigning variables ...
         %%% ... from ResMeasure object
         point = self.Position;
         [xLine, yLine, zLine] = self.IntensityLines{:};
         [xPeak, yPeak, zPeak] = csmu.cell2csl(num2cell(self.PeakValue));
         [xWidth, yWidth, zWidth] = csmu.cell2csl(num2cell(self.PeakWidth));
         [xLoc, yLoc, zLoc] = csmu.cell2csl(num2cell(self.PeakPosition));
         [xEdges, yEdges, zEdges] = self.PeakEdges{:};
         [xHalfMaxes, yHalfMaxes, zHalfMaxes] = ...
            csmu.cell2csl(num2cell(self.PeakEdgeValue));
         background = self.PeakBackground;
         
         %%% ... from volume
         volSize = size(V);
         
         %% Generating View
         %%% View Width
         if isempty(viewWidth)
            viewWidth = min(defaultViewWidth, max(volSize));
         end
         xlim = point(1) + ([-1 1] * viewWidth / 2);
         ylim = point(2) + ([-1 1] * viewWidth / 2);
         zlim = point(3) + ([-1 1] * viewWidth / 2);
         
         %%% Window Selections
         xWindowSel = max(round(xlim(1)), 1):min(round(xlim(2)), volSize(2));
         yWindowSel = max(round(ylim(1)), 1):min(round(ylim(2)), volSize(1));
         zWindowSel = max(round(zlim(1)), 1):min(round(zlim(2)), volSize(3));
         
         xyWindow = {yWindowSel, xWindowSel};
         xzWindow = {zWindowSel, xWindowSel};         
         yzWindow = {zWindowSel, yWindowSel};
         
         %%% Projections / Slices         
         if doMaxProjection
            L.info('\tGenerating Max Projections');
            xy = csmu.maxProject(V, 3);
            xz = permute(csmu.maxProject(V, 1), [2 1]);
            yz = permute(csmu.maxProject(V, 2), [2 1]);
         else
            xSlice = [floor(point(1)), ceil(point(1))];
            ySlice = [floor(point(2)), ceil(point(2))];
            zSlice = [floor(point(3)), ceil(point(3))];
            xMultiplier = abs(xSlice([2, 1]) - point(1));
            yMultiplier = abs(ySlice([2, 1]) - point(2));
            zMultiplier = abs(zSlice([2, 1]) - point(3));
            
            if sum(xMultiplier) < (1 - eps)
               xMultiplier = [1 0];
            end
            
            if sum(yMultiplier) < (1 - eps)
               yMultiplier = [1, 0];
            end
            
            if sum(zMultiplier) < (1 - eps)
               zMultiplier = [1 0];
            end
            
            xy = V(:, :, zSlice(1)) * zMultiplier(1) ... 
               + V(:, :, zSlice(2)) * zMultiplier(2);
            xz = V(ySlice(1), :, :) * yMultiplier(1) ...
               + V(ySlice(2), :, :) * yMultiplier(2);
            xz = permute(squeeze(xz), [2 1]);
            yz = V(:, xSlice(1), :) * xMultiplier(1) ...
               + V(:, xSlice(2), :) * xMultiplier(2);
            yz = permute(squeeze(yz), [2 1]);
         end
         
         %%% Window Scale
         xyWindowed = xy(xyWindow{:});
         xyScale = csmu.range(xyWindowed);
         
         xzWindowed = xz(xzWindow{:});
         xzScale = csmu.range(xzWindowed);
         
         yzWindowed = yz(yzWindow{:});
         yzScale = csmu.range(yzWindowed);
         
         allScale = csmu.range(cat(2, xyScale, xzScale, yzScale));
         
         %%% Intensity Lines
         displayRangeExpansionFactor = 0.02;         
         
         annotationArrowLength = viewWidth * 0.11;          
         annotationGap = annotationArrowLength * 0.08;  
         arrowVector = [annotationArrowLength, 0];
         
         voxelResolution = 0.5 * ones(1, 3);
         
         dref = displayRangeExpansionFactor;
         ag = annotationGap;         
         av = arrowVector;
         
         xDomain = 1:length(xLine);
         xRange = xLine;
         xPeakDomain = xLoc;
         xPeakRange = xPeak;
         xWidth_um = xWidth * voxelResolution(1);
         xDisplayRange = csmu.expandRange([background, xPeak], dref);
         
         xLeftAnnotationDomain = xEdges(1) - ag - av;
         xRightAnnotationDomain = xEdges(2) + ag + av;
         xAnnotationRange = xHalfMaxes * ones(1, 2);
         
         yDomain = 1:length(yLine);
         yRange = yLine;
         yPeakDomain = yLoc;
         yPeakRange = yPeak;
         yWidth_um = yWidth * voxelResolution(2);
         yDisplayRange = csmu.expandRange([background, yPeak], dref);
         
         yLeftAnnotationDomain = yEdges(1) - ag - av;
         yRightAnnotationDomain = yEdges(2) + ag + av;
         yAnnotationRange = yHalfMaxes * ones(1, 2);
         
         zDomain = 1:length(zLine);
         zRange = zLine;
         zPeakDomain = zLoc;
         zPeakRange = zPeak;
         zWidth_um = zWidth * voxelResolution(3);
         zDisplayRange = csmu.expandRange([background, zPeak], dref);
         
         zLeftAnnotationDomain = zEdges(1) - ag - av;
         zRightAnnotationDomain = zEdges(2) + ag + av;
         zAnnotationRange = zHalfMaxes * ones(1, 2);
         
         xy_x_WindowLine = [
            0.5,              point(2)
            0.5 + volSize(2), point(2)];
         
         xy_y_WindowLine = [
            point(1),         0.5
            point(1),         0.5 + volSize(1)];
         
         xz_x_WindowLine = [
            0.5,              point(3)
            0.5 + volSize(2), point(3)];
         
         xz_z_WindowLine = [
            point(1),         0.5
            point(1),         0.5 + volSize(3)];
         
         yz_y_WindowLine = [
            0.5,              point(3)
            0.5 + volSize(1), point(3)];
         
         yz_z_WindowLine = [
            point(2),         0.5
            point(2),         0.5 + volSize(3)];
         %% Plotting
         L.info('\tGenerating Plot');
         csmu.FigureBuilder.setDefaults;
         imPlots = csmu.plotBuilders(1, 2);
         imPlots(1) = csmu.ImagePlot;
         imPlots(1).Colormap = cmap;
         for iPlot = 2:length(imPlots)
            imPlots(iPlot) = copy(imPlots(1));
         end
         imPlots(1).I = xz;
         imPlots(1).ColorLimits = allScale;
         imPlots(2).I = yz;
         imPlots(2).ColorLimits = allScale;
         
         linePlots = csmu.plotBuilders(1, 3);
         linePlots(1) = csmu.LinePlot;
         linePlots(1).LineSpec = {'-'};
         if inputs.DoDarkMode
            linePlots(1).Color = lightGrey;
         else
            linePlots(1).Color = 'k';
         end
         linePlots(1).LineWidth = 3.5;
         for iPlot = 2:length(linePlots)
            linePlots(iPlot) = copy(linePlots(1));
         end
         linePlots(1).X = xDomain;
         linePlots(1).Y = xRange;
         linePlots(2).X = yDomain;
         linePlots(2).Y = yRange;
         linePlots(3).X = zRange;
         linePlots(3).Y = zDomain;
         
         imLinePlots = csmu.plotBuilders(1, 4);
         imLinePlots(1) = csmu.LinePlot;
         imLinePlots(1).LineSpec = {':'};
         imLinePlots(1).Color = [lightGrey, 0.5];
         imLinePlots(1).LineWidth = 1.5;
         for iPlot = 2:length(imLinePlots)
            imLinePlots(iPlot) = copy(imLinePlots(1));
         end
         imLinePlots(1).X = xz_x_WindowLine(:, 1);
         imLinePlots(1).Y = xz_x_WindowLine(:, 2);
         imLinePlots(2).X = xz_z_WindowLine(:, 1);
         imLinePlots(2).Y = xz_z_WindowLine(:, 2);
         imLinePlots(3).X = yz_y_WindowLine(:, 1);
         imLinePlots(3).Y = yz_y_WindowLine(:, 2);
         imLinePlots(4).X = yz_z_WindowLine(:, 1);
         imLinePlots(4).Y = yz_z_WindowLine(:, 2);
         
         pointPlots = csmu.plotBuilders(1, 3);
         pointPlots(1) = csmu.ScatterPlot;
         pointPlots(1).Marker = 'v';
         pointPlots(1).MarkerEdgeColor = 'none';
         pointPlots(1).MarkerFaceColor = 'r';
         pointPlots(1).LineWidth = 1.5;
         for iPlot = 2:length(pointPlots)
            pointPlots(iPlot) = copy(pointPlots(1));
         end
         pointPlots(1).X = xPeakDomain;
         pointPlots(1).Y = xPeakRange;
         pointPlots(2).X = yPeakDomain;
         pointPlots(2).Y = yPeakRange;
         pointPlots(3).Marker = '>';
         pointPlots(3).X = zPeakRange;
         pointPlots(3).Y = zPeakDomain;
         for iPlot = 1:length(pointPlots)
            if ~inputs.DoShowPeakMarker
               pointPlots(iPlot).Visible = 'off';
            end
         end
         
         texts = csmu.plotBuilders(1, 4);
         texts(1) = csmu.TextPlot;
         texts(1).Position = [0 1];
         texts(1).Units = 'normalized';
         texts(1).FontName = inputs.FontName;
         texts(1).FontSize = 12 ;
         texts(1).VerticalAlignment = 'top';
         if inputs.DoDarkMode
            texts(1).Color = lightGrey;
         else
            texts(1).Color = 'k';
         end
         for iPlot = 2:length(texts)
            texts(iPlot) = copy(texts(1));
         end
         texts(1).Text = sprintf('FWHM, X = %.2f um', xWidth_um);
         texts(2).Text = sprintf('FWHM, Y = %.2f um', yWidth_um);
         texts(3).Text = sprintf('FWHM, Z\n  = %.2f um', zWidth_um);
         for iText = 1:3
            if ~inputs.DoShowMeasurementText
               texts(iText).Visible = 'off';               
            end            
         end
         texts(4).Interpreter = 'none';
         texts(4).FontSize = 9;
         texts(4).Text = annotationText;
         if isempty(annotationText)
            texts(4).Visible = 'off';
         end
         
         gs = csmu.GridSpec(3, 5);
         gs.VSpace = 0.3;
         gs.HSpace = 0.3;
         axisConfigs(1, 6) = csmu.AxisConfiguration;
         axisConfigs(1).TickDir = 'out';
         axisConfigs(1).Color = 'none';
         if inputs.DoDarkMode
            axisConfigs(1).XColor = lightGrey;
            axisConfigs(1).YColor = lightGrey;
         else
            axisConfigs(1).XColor = 'k';
            axisConfigs(1).YColor = 'k';
         end
         
         axisConfigs(1).XLabel.FontName = inputs.FontName;
         axisConfigs(1).YLabel.FontName = inputs.FontName;
         axisConfigs(1).FontSize = 25;
         axisConfigs(1).LabelFontSizeMultiplier = 1;
         axisConfigs(1).Visible = 'on';
         axisConfigs(1).LineWidth = 1;
         for iAc = 2:length(axisConfigs)
            axisConfigs(iAc) = copy(axisConfigs(1));
         end
         
         if doShowHeightAxis
            axisConfigs(1).YTick = [0 ceil(max(xLine))];
            axisConfigs(2).YTick = [0 ceil(max(yLine))];
            axisConfigs(1).YAxisLocation = 'right';
            axisConfigs(2).YAxisLocation = 'right';
            axisConfigs(3).XTick = [0 ceil(max(zLine))];
         else
            axisConfigs(1).YAxis.Visible = 'off';
            axisConfigs(2).YAxis.Visible = 'off';
            axisConfigs(3).XAxis.Visible = 'off';
         end
         
         axisConfigs(1).Position = gs(1, 2:3);
         axisConfigs(1).XLim = xlim;
         axisConfigs(1).XLabel.String = 'X';
         axisConfigs(1).XLabel.VerticalAlignment = 'top';         
         axisConfigs(1).YLim = xDisplayRange;
         
         axisConfigs(2).Position = gs(1, 4:5);
         axisConfigs(2).XLim = ylim;
         axisConfigs(2).XLabel.String = 'Y';
         axisConfigs(2).XLabel.VerticalAlignment = 'top';
         axisConfigs(2).YLim = yDisplayRange;
         
         axisConfigs(3).Position = gs(2:3, 1);
         axisConfigs(3).YAxis.Visible = 'on';
         axisConfigs(3).YAxisLocation = 'right';
         axisConfigs(3).XDir = 'reverse';
         axisConfigs(3).YLim = zlim;
         axisConfigs(3).XLim = zDisplayRange;
         axisConfigs(3).YLabel.String = 'Z';
         axisConfigs(3).YLabel.Rotation = 0;
         axisConfigs(3).YLabel.VerticalAlignment = 'middle';
         axisConfigs(3).YLabel.HorizontalAlignment = 'center';
         
         % axisConfigs(3).YLabel = '';
         axisConfigs(3).YTick = axisConfigs(3).YLim;
         axisConfigs(3).YTickLabel = {'', ''};
         for iAc = 1:2
            % axisConfigs(iAc).XLabel = '';
            axisConfigs(iAc).XTick = axisConfigs(iAc).XLim;
            axisConfigs(iAc).XTickLabel = {'', ''};
         end
         
         for iAc = 4:6
            axisConfigs(iAc).Visible = 'off';
         end
         axisConfigs(4).Position = gs(2:3, 2:3);
         axisConfigs(4).XLim = xlim;
         axisConfigs(4).YLim = zlim;
         axisConfigs(5).Position = gs(2:3, 4:5);
         axisConfigs(5).XLim = ylim;
         axisConfigs(5).YLim = zlim;
         axisConfigs(6).Position = gs(1, 1);
         
         %%% Annotations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         aPlots = csmu.plotBuilders(1, 6);
         for iPlot = 1:6
            aPlots(iPlot) = csmu.AnnotationPlot();
            aPlots(iPlot).TextArrowFontName = inputs.FontName;
            aPlots(iPlot).TextArrowFontSize = 40;
            aPlots(iPlot).LineType = 'textarrow';
            if inputs.DoDarkMode
               aPlots(iPlot).Color = lightGrey;
            else
               aPlots(iPlot).Color = 'k';
            end
            aPlots(iPlot).TextArrowTextMargin = 15;
            aPlots(iPlot).TextArrowHeadStyle = 'vback2';
         end
         
         arrowLength = viewWidth * 0.11;
         gap = arrowLength * 0.08;
         
         % x left
         aPlots(1).X = xLeftAnnotationDomain;
         aPlots(1).Y = xAnnotationRange;
         aPlots(1).TextArrowString = sprintf('%.1f \x00B5m ', xWidth / 2);
         aPlots(1).TextArrowHorizontalAlignment = 'right';
         aPlots(1).TextArrowVerticalAlignment = 'middle';
         
         % x right
         aPlots(2).X = xRightAnnotationDomain;
         aPlots(2).Y = xAnnotationRange;
         
         % y left
         aPlots(3).X = yLeftAnnotationDomain;
         aPlots(3).Y = yAnnotationRange;
         aPlots(3).TextArrowString = sprintf('%.1f \x00B5m ', yWidth / 2);
         aPlots(3).TextArrowHorizontalAlignment = 'right';
         aPlots(3).TextArrowVerticalAlignment = 'middle';
         
         % y right
         aPlots(4).X = yRightAnnotationDomain;
         aPlots(4).Y = yAnnotationRange;
         
         
         % z left
         aPlots(5).Y = zLeftAnnotationDomain;
         aPlots(5).X = zAnnotationRange;
         
         % z right
         aPlots(6).Y = zRightAnnotationDomain;
         aPlots(6).X = zAnnotationRange;
         aPlots(6).TextArrowString = sprintf('%.1f \x00B5m ', zWidth / 2);
         aPlots(6).TextArrowHorizontalAlignment = 'left';
         aPlots(6).TextArrowVerticalAlignment = 'bottom';
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         subplotStacks = cell(1, 3);
         for iPeak = 1:3
            subplotStacks{iPeak} = linePlots(iPeak);
            if self.PeakValid(iPeak)
               aPlotIdxs = (1:2) + ((iPeak - 1) * 2);               
               
               subplotStacks{iPeak} = [
                  subplotStacks{iPeak}, ...
                  pointPlots(iPeak), ...
                  texts(iPeak), ...
                  aPlots(aPlotIdxs)];
            end
         end         
         
         fb = csmu.FigureBuilder;
         if inputs.DoDarkMode
            fb.Color = darkGrey;
         else
            fb.Color = 'w';
         end
         fb.DoUseSubplot = false;
         fb.PlotBuilders = [...
            subplotStacks, ...
            {[imPlots(1), imLinePlots(1:2)], ...
            [imPlots(2), imLinePlots(3:4)], ...
            texts(4)}];
         fb.AxisConfigs = axisConfigs;
         figHeight = 800;
         fb.Position = [908, 250, (gs.FigureAspectRatio * figHeight), ...
            figHeight];
         fb.LinkAxes = {[1 4], 'x'; [2 5], 'x'; [3 4 5], 'y'};
      end
   end
   
   methods (Static)
      function resMeasure = calculate(V, point, varargin)
         fcnName = strcat('csmu.', mfilename, '.calculate');
         L = csmu.Logger(fcnName);
         
         %% Parsing Inputs
         L.info('Parsing inputs');
         parserSpec = {
            {'p', 'DoRefinePointBy3DCentroid', false}
            {'p', 'CentroidSearchRadius', []}
            {'p', 'DoRefinePointBy1DPeaks', true}
            {'p', 'Maximum1DRefineIterations', 25}
            {'p', 'Maximum1DPeakDistance', 5}
            {'p', 'PeakLocationReference', 'maximum', {'maximum', 'center'}}
            {'p', 'WidthReference', 'halfheight', {'halfheight', 'halfprom'}}
            {'p', 'FindpeaksArgs', {}}
            {'p', 'BackgroundPrctile', 20}            
         };
         ip = csmu.constructInputParser(...
            parserSpec, ...
            'Name', fcnName, ...
            'Args', varargin);
         inputs = ip.Results;
         
         %% Locate Maximum Within Radius
         if inputs.DoRefinePointBy3DCentroid
            L.debug('Attempting to refine point by 3D centroid estimation');
            
            searchRadius = inputs.CentroidSearchRadius;
            if isempty(searchRadius)
               % default search radius (in voxels) is 5% of the largest 
               % dimension of the input volume V
               searchRadius = 0.05 * max(size(V));
            end
            
            windowSideLength = (2 * inputs.PeakSearchRadius) + 1;
            windowSize = repmat(windowSideLength, 1, 3);
            lims = csmu.ImageRef(windowSize);
            lims.zeroCenter;
            limShiftTransform = csmu.Transform;
            limShiftTransform.TranslationRotationOrder = csmu.IndexOrdering.XY;
            limShiftTransform.Translation = point;
            lims = limShiftTransform.warpRef(lims);
            vWindowed = csmu.changeView(V, csmu.ImageRef(V), lims);
            [maxVal, maxIdx] = max(vWindowed(:));
            vWindowedThresh = (vWindowed >= maxVal);
            stats = regionprops3(vWindowedThresh, vWindowed, ...
               'WeightedCentroid');
            
            % transform centroid points back to the volume's space
            pointCandidates = stats.WeightedCentroid ...
               - ((windowSize + 1) / 2) ...
               + point;
            candidateDistances = sum((pointCandidates - point) .^ 2, 2);
            [~, candidateIdx] = min(candidateDistances);
            candidateDistance = sqrt(candidateDistances(candidateIdx));
            newPoint = pointCandidates(candidateIdx, :);
            
            L.info(['Point has been updated to [%s] from [%s],\n\ta ', ...
               'distance of %.1f volxels apart.'], num2str(newPoint), ...
               num2str(point), candidateDistance);
            point = newPoint;
         end
         
         %% Generating Line and View         
         findPeaksArgs = [
            {'WidthReference', inputs.WidthReference}, ...
            inputs.FindpeaksArgs];         
         
         L.info('\tGenerating Line Samples');
         peakPoint = point;         
         
         L.info('\tDetermining Peak Locations');
         iIter = 0;
         while true
            [xl, yl, zl] = csmu.arrayLineSample(V, peakPoint);
            
            peakBackground = prctile(...
               cat(1, xl, yl, zl), ...
               inputs.BackgroundPrctile, ...
               'all');
            
            L.debug('%d - Peak background found to be %.1f', ...
               iIter, peakBackground)
            
            [xPeakVals, xLocs, xWGuesses, xPs] = ...
               findpeaks(xl, findPeaksArgs{:});
            [yPeakVals, yLocs, yWGuesses, yPs] = ...
               findpeaks(yl, findPeaksArgs{:});
            [zPeakVals, zLocs, zWGuesses, zPs] = ...
               findpeaks(zl, findPeaksArgs{:});
            
            xExist = ~isempty(xPeakVals);
            yExist = ~isempty(yPeakVals);
            zExist = ~isempty(zPeakVals);
                        
            % Get the index of the peak closest to the target point
            if xExist
               [xSqD, xIdx] = min((xLocs - peakPoint(1)) .^ 2);
               xPeakVal = xPeakVals(xIdx);
               xLoc = xLocs(xIdx);
               xWGuess = xWGuesses(xIdx);
               xP = xPs(xIdx);
               
               [xEdges, xWidthHeight] = ...
                  csmu.ResolutionMeasurement.edgeHelper(...
                  xl, ...
                  xWGuess, ...
                  xPeakVal, ...
                  xLoc, ...
                  peakBackground);
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  xLoc = mean(xEdges);
                  xSqD = (xLoc - peakPoint(1)) .^ 2;
               end
               
               xValid = sqrt(xSqD) <= inputs.Maximum1DPeakDistance;
            else
               xLoc = 0;
               xPeakVal = 0;
               xP = 0;
               xEdges = [0, 0];
               xWidthHeight = 0;
               xValid = false;
            end
            
            if yExist
               [ySqD, yIdx] = min((yLocs - peakPoint(2)) .^ 2);
               yPeakVal = yPeakVals(yIdx);
               yLoc = yLocs(yIdx);
               yWGuess = yWGuesses(yIdx);
               yP = yPs(yIdx);
               
               [yEdges, yWidthHeight] = ...
                  csmu.ResolutionMeasurement.edgeHelper(...
                  yl, ...
                  yWGuess, ...
                  yPeakVal, ...
                  yLoc, ...
                  peakBackground);
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  yLoc = mean(yEdges);
                  ySqD = (yLoc - peakPoint(2)) .^ 2;
               end
               
               yValid = sqrt(ySqD) <= inputs.Maximum1DPeakDistance;
            else
               yLoc = 0;
               yPeakVal = 0;
               yP = 0;
               yEdges = [0, 0];
               yWidthHeight = 0;
               yValid = false;
            end
            
            if zExist
               [zSqD, zIdx] = min((zLocs - peakPoint(3)) .^ 2);
               zPeakVal = zPeakVals(zIdx);
               zLoc = zLocs(zIdx);
               zWGuess = zWGuesses(zIdx);
               zP = zPs(zIdx);
               
               [zEdges, zWidthHeight] = ...
                  csmu.ResolutionMeasurement.edgeHelper(...
                  zl, ...
                  zWGuess, ...
                  zPeakVal, ...
                  zLoc, ...
                  peakBackground);
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  zLoc = mean(zEdges);
                  zSqD = (zLoc - peakPoint(3)) .^ 2;
               end
               
               zValid = sqrt(zSqD) <= inputs.Maximum1DPeakDistance;
            else
               zLoc = 0;
               zPeakVal = 0;
               zP = 0;
               zEdges = [0, 0];
               zWidthHeight = 0;
               zValid = false;
            end
            
            peakPoint = [xLoc, yLoc, zLoc];
            
            if all([xExist, yExist, zExist])                                                                                          
               rawDelta = sqrt(sumsqr(peakPoint - point));
               
               if inputs.DoRefinePointBy1DPeaks                                    
                  iterDelta = sqrt(sum([xSqD, ySqD, zSqD]));
                  
                  L.debug(strcat(...
                     '%d - Point has been updated to \n[%s] from the', ...
                     ' original point \n[%s]; a distance of %.1f volxels ', ...
                     ' apart.\nIteration update distance is %.1f voxels.'), ...
                     iIter, ...
                     num2str(peakPoint), ...
                     num2str(point), ...
                     rawDelta, ...
                     iterDelta);
                  
                  if iterDelta < 1
                     break
                  elseif iIter >= inputs.Maximum1DRefineIterations
                     L.debug('Maximum iterations reached, breaking loop');
                     break                     
                  else
                     iIter = iIter + 1;
                     continue
                  end
               else                  
                  L.debug(strcat(...
                     'Peak point found to be\n[%s]; sample point is\n[%s].', ...
                     ' Distance between them is %.1f voxels.'), ...
                     num2str(peakPoint), ...
                     num2str(point), ...
                     rawDelta);
                  break
               end
            else
               L.debug(strcat('Peaks were not found in all dimensions ', ...
                  ' [x = %s, y = %s, z = %s].'), ...
                  csmu.bool2string(xExist), ...
                  csmu.bool2string(yExist), ...
                  csmu.bool2string(zExist));
               break
            end
         end
         
         resMeasure = csmu.ResolutionMeasurement;
         resMeasure.Image = V;
         resMeasure.ImageRef = csmu.ImageRef(V);
         
         if inputs.DoRefinePointBy1DPeaks && all([xExist, yExist, zExist])
            resMeasure.Position = peakPoint;
         else
            resMeasure.Position = point;
         end
         
         resMeasure.PeakBackground = peakBackground;
         resMeasure.PeakPosition =   peakPoint;
         
         resMeasure.IntensityLines = {xl,           yl,           zl};         
         
         resMeasure.PeakValue =      [xPeakVal,     yPeakVal,     zPeakVal];
         resMeasure.PeakProminance = [xP,           yP,           zP];         
         resMeasure.PeakEdges =      {xEdges,       yEdges,       zEdges};         
         resMeasure.PeakEdgeValue =  [xWidthHeight, yWidthHeight, zWidthHeight];                  
         resMeasure.PeakValid =      [xValid,       yValid,       zValid];
      end

      
      function [varargout] = edgeHelper(intensity, width, peak, loc, ...
            background)
         intensity = intensity - background;
         intensity(intensity < 0) = 0;
         peak = peak - background;
         
         lims = [1, length(intensity)];
         halfWide = width / 2;
         searchWidth = max(3, halfWide);
         halfPeak = peak / 2;
         
         leftSearch = colon(...
            round(csmu.bound((loc - (halfWide / 2)) - (searchWidth / 2), ...
            lims(1), lims(2))), ...
            round(csmu.bound((loc - (halfWide / 2)) + (searchWidth / 2), ...
            lims(1), lims(2))));
         leftIntensity = intensity(leftSearch);
         
         if true
            while true
               leftNonPeakMask = leftIntensity < halfPeak;
               leftNonPeakSearch = leftSearch(leftNonPeakMask);
               
               if any(leftNonPeakSearch)
                  break
               else
                  leftSearch = leftSearch - 1;
                  leftIntensity = intensity(leftSearch);
               end
            end
            
            leftSearch = (0:1) + leftNonPeakSearch(end);
            leftIntensity = intensity(leftSearch);
         end
         
         rightSearch = colon(...
            round(csmu.bound((loc + (halfWide / 2)) - (searchWidth / 2), ...
            lims(1), lims(2))), ...
            round(csmu.bound((loc + (halfWide / 2)) + (searchWidth / 2), ...
            lims(1), lims(2))));
         rightIntensity = intensity(rightSearch);
         
         
         if true
            while true
               rightNonPeakMask = rightIntensity < halfPeak;
               rightNonPeakSearch = rightSearch(rightNonPeakMask);
               
               if any(rightNonPeakSearch)
                  break
               else
                  rightSearch = rightSearch + 1;
                  rightIntensity = intensity(rightSearch);
               end
            end
            
            rightSearch = (-1:0) + rightNonPeakSearch(1);
            rightIntensity = intensity(rightSearch);
         end
         
         leftEdge = interp1(leftIntensity, leftSearch, halfPeak);
         rightEdge = interp1(rightIntensity, rightSearch,  halfPeak);
         
         assert(~any(isnan([leftEdge, rightEdge])));
         
         varargout = {
            [leftEdge, rightEdge], background + halfPeak};
      end
   end
end