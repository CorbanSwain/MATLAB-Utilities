classdef ResolutionMeasurement < csmu.Object
   properties
      ImageRef csmu.ImageRef
      Position
      IntensityLines
      PeakValid = [false, false, false]
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
         if xzScale(1) >= xzScale(2)
            xzScale = mean(xzScale, 'all') + [-0.5, 0.5];
         end
         
         yzWindowed = yz(yzWindow{:});
         yzScale = [min(yzWindowed(:)), max(yzWindowed(:))];
         if yzScale(1) >= yzScale(2)
            yzScale = mean(yzScale, 'all') + [-0.5, 0.5];
         end
         
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
         ip.addParameter('VoxelResolution', 0.5);
         ip.addParameter('DoShowSampleAxis', true);
         ip.addParameter('DoShowAxisLabels', true);
         ip.addParameter('PlotLayout', 1);
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
         muChar = sprintf('\x00B5');
         
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
         halfViewWidth = viewWidth / 2;
         windowVector = [-1 1] * halfViewWidth;
         xlim = point(1) + windowVector;
         ylim = point(2) + windowVector;
         zlim = point(3) + windowVector;
         
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
         xyScale = csmu.range(xyWindowed, 'all');
         
         xzWindowed = xz(xzWindow{:});
         xzScale = csmu.range(xzWindowed, 'all');
         
         yzWindowed = yz(yzWindow{:});
         yzScale = csmu.range(yzWindowed, 'all');
         
         allScale = csmu.range(cat(2, xyScale, xzScale, yzScale));

         defaultRange = [0, allScale(2)];
         
         if allScale(1) >= allScale(2)
            colorDisplayScale = csmu.range(self.Image, 'all');

            if colorDisplayScale(1) >= colorDisplayScale(2)
               if colorDisplayScale(1) < 0
                  colorDisplayScale = ...
                     mean(colorDisplayScale, 'all') + [-0.5, 0.5];
               else
                  colorDisplayScale = [0, 1];
               end
            end
         else
            colorDisplayScale = allScale;
         end
         
         %%% Plot Component and Property Computations
         displayRangeExpansionFactor = 0.02;         
         
         annotationArrowLength = viewWidth * 0.11;          
         annotationGap = annotationArrowLength * 0.22;  
         arrowVector = [annotationArrowLength, 0];
         annotationFmt = sprintf('%%.1f %sm', muChar);
         verboseAnnotationFmt = sprintf('FWHM, %%s = %%.2f %sm', muChar);
         
         voxelResolution = inputs.VoxelResolution .* ones(1, 3);
         
         dref = displayRangeExpansionFactor;
         ag = annotationGap;         
         av = arrowVector;
         
         xDomain = 1:length(xLine);
         xRange = xLine;                  
         xPeakDomain = xLoc;
         xPeakRange = xPeak;
         xWidth_um = xWidth * voxelResolution(1);
         if self.PeakValid(1)
            if ~any(isnan(xEdges))
               xEdgesIdx = csmu.bound(round(xEdges), 1, length(xLine));
               xLabelRange = [
                  background, ...
                  max(max(xLine(xEdgesIdx(1):xEdgesIdx(2)), [], 'all'), ...
                  background + eps(background))];
            else
               xLabelRange = [...
                  background, ...
                  max(xPeak, background + eps(background))];
            end
         else
            xLabelRange = defaultRange;
         end
         xDisplayRange = csmu.expandRange(xLabelRange, dref);
         
         xLeftAnnotationDomain = xEdges(1) - ag - av;
         xRightAnnotationDomain = xEdges(2) + ag + av;
         if any(xLeftAnnotationDomain < xlim(1)) ...
               || any(xRightAnnotationDomain > xlim(2))
            
            tempHead = max(xlim(1), xEdges(1));
            xLeftAnnotationDomain = tempHead + ag + av;            
            tempHead = min(xlim(2), xEdges(2));
            xRightAnnotationDomain = tempHead - ag - av;            
            xArrowAnnotationLayout = 'inner';
         else
            xArrowAnnotationLayout = 'outer';
         end
         xAnnotationRange = xHalfMaxes * ones(1, 2);
         xAnnotation = sprintf(annotationFmt, xWidth_um);
         xAnnotationVerbose = sprintf(verboseAnnotationFmt, 'X', xWidth_um);
         
         yDomain = 1:length(yLine);
         yRange = yLine;
         yPeakDomain = yLoc;
         yPeakRange = yPeak;
         yWidth_um = yWidth * voxelResolution(2);
         if self.PeakValid(2)
            if ~any(isnan(yEdges))
               yEdgesIdx = csmu.bound(round(yEdges), 1, length(yLine));
               yLabelRange = [
                  background, ...
                  max(max(yLine(yEdgesIdx(1):yEdgesIdx(2)), [], 'all'), ...
                  background + eps(background))];
            else
               yLabelRange = [...
                  background, ...
                  max(yPeak, background + eps(background))];
            end
         else
            yLabelRange = defaultRange;
         end
         yDisplayRange = csmu.expandRange(yLabelRange, dref);
         
         yLeftAnnotationDomain = yEdges(1) - ag - av;
         yRightAnnotationDomain = yEdges(2) + ag + av;
         if any(yLeftAnnotationDomain < ylim(1)) ...
               || any(yRightAnnotationDomain > ylim(2))
            
            tempHead = max(ylim(1), yEdges(1));
            yLeftAnnotationDomain = tempHead + ag + av;
            tempHead = min(ylim(2), yEdges(2));
            yRightAnnotationDomain = tempHead - ag - av;
            
            yArrowAnnotationLayout = 'inner';
         else
            yArrowAnnotationLayout = 'outer';
         end
         yAnnotationRange = yHalfMaxes * ones(1, 2);
         yAnnotation = sprintf(annotationFmt, yWidth_um);
         yAnnotationVerbose = sprintf(verboseAnnotationFmt, 'Y', yWidth_um);
         
         zDomain = 1:length(zLine);
         zRange = zLine;
         zPeakDomain = zLoc;
         zPeakRange = zPeak;
         zWidth_um = zWidth * voxelResolution(3);
         if self.PeakValid(3)
            if ~any(isnan(zEdges))
               zEdgesIdx = csmu.bound(round(zEdges), 1, length(zLine));
               zLabelRange = [
                  background, ...
                  max(max(zLine(zEdgesIdx(1):zEdgesIdx(2)), [], 'all'), ...
                  background + eps(background))];
            else
               zLabelRange = [...
                  background, ...
                  max(zPeak, background + eps(background))];
            end
         else
            zLabelRange = defaultRange;
         end
         zDisplayRange = csmu.expandRange(zLabelRange, dref);
         
         zLeftAnnotationDomain = zEdges(1) - ag - av;
         zRightAnnotationDomain = zEdges(2) + ag + av;
         if any(zLeftAnnotationDomain < zlim(1)) ...
               || any(zRightAnnotationDomain > zlim(2))
            
            tempHead = max(zlim(1), zEdges(1));
            zLeftAnnotationDomain = tempHead + ag + av;
            tempHead = min(zlim(2), zEdges(2));
            zRightAnnotationDomain = tempHead - ag - av;
            
            zArrowAnnotationLayout = 'inner';
         else
            zArrowAnnotationLayout = 'outer';
         end  
         zAnnotationRange = zHalfMaxes * ones(1, 2);
         zAnnotation = sprintf(annotationFmt, zWidth_um);
         zAnnotationVerbose = sprintf(verboseAnnotationFmt, 'Z', zWidth_um);
         
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
         %%% Colors         
         if inputs.DoDarkMode
            foregroundColor = lightGrey;
            backgroundColor = darkGrey;
            peakMarkerColor = [1, 0.25, 0.25];
         else
            foregroundColor = 'k';
            backgroundColor = 'w';
            peakMarkerColor = 'r';
         end
         
         %%% Plot Templates
         imPlotTemplate = csmu.ImagePlot();
         imPlotTemplate.Colormap = cmap;
         imPlotTemplate.ColorLimits = colorDisplayScale;
         
         linePlotTemplate = csmu.LinePlot();
         linePlotTemplate.LineSpec = {'-'};
         linePlotTemplate.Color = foregroundColor;
         linePlotTemplate.LineWidth = 3.5;
         
         windowLinePlotTemplate = csmu.LinePlot();
         windowLinePlotTemplate.LineSpec = {':'};
         windowLinePlotTemplate.Color = [lightGrey, 0.5];
         windowLinePlotTemplate.LineWidth = 1.5;         
         
         peakPointPlotTemplate = csmu.ScatterPlot();
         peakPointPlotTemplate.MarkerEdgeColor = 'none';
         peakPointPlotTemplate.MarkerFaceColor = peakMarkerColor;
         peakPointPlotTemplate.LineWidth = 1.5;
         if inputs.DoShowPeakMarker
            peakPointPlotTemplate.Visible = 'on';
         else
            peakPointPlotTemplate.Visible = 'off';
         end
         peakPointMarker = struct(...
            'above', 'v', ...
            'left', '>', ...
            'right', '<', ...
            'below', '^');
         
         textAnnotationTemplate = csmu.TextPlot();
         textAnnotationTemplate.Position = [0 1];
         textAnnotationTemplate.Units = 'normalized';
         textAnnotationTemplate.FontName = inputs.FontName;
         textAnnotationTemplate.FontSize = 12;
         textAnnotationTemplate.VerticalAlignment = 'top';
         textAnnotationTemplate.Color = foregroundColor;       
         if inputs.DoShowMeasurementText
            textAnnotationTemplate.Visible = 'on';
         else
            textAnnotationTemplate.Visible = 'off';
         end
         
         longTextAnnotationTemplate = copy(textAnnotationTemplate);
         longTextAnnotationTemplate.Interpreter = 'none';
         longTextAnnotationTemplate.FontSize = 9;
         if isempty(annotationText)
            longTextAnnotationTemplate.Visible = 'off';
         else
            longTextAnnotationTemplate.Visible = 'on';
         end
         
         arrowAnnotationTemplate = csmu.AnnotationPlot();
         arrowAnnotationTemplate.TextArrowFontName = inputs.FontName;
         arrowAnnotationTemplate.TextArrowFontSize = 24;
         arrowAnnotationTemplate.LineType = 'textarrow';
         arrowAnnotationTemplate.TextArrowTextMargin = 15;
         arrowAnnotationTemplate.TextArrowHeadStyle = 'vback2';
         arrowAnnotationTemplate.Color = foregroundColor;
         
         axisTemplate = csmu.AxisConfiguration();
         axisTemplate.TickDir = 'out';
         axisTemplate.Color = 'none';
         axisTemplate.XColor = foregroundColor;
         axisTemplate.YColor = foregroundColor;
         axisTemplate.XLabel.FontName = inputs.FontName;
         axisTemplate.YLabel.FontName = inputs.FontName;
         axisTemplate.FontSize = 25;
         axisTemplate.LabelFontSizeMultiplier = 1;
         axisTemplate.Visible = 'on';
         axisTemplate.LineWidth = 1;
                  
         fb = csmu.FigureBuilder();
         fb.Color = backgroundColor;
         fb.DoUseSubplot = false;
         
         L.info('\tGenerating Plot');
         csmu.FigureBuilder.setDefaults();
         
         switch inputs.PlotLayout            
            case 1
               %%% Generation of Plot Objects
               imPlots = csmu.plotBuilders(1, 2);
               for iPlot = 1:length(imPlots)
                  imPlots(iPlot) = copy(imPlotTemplate);
               end
               imPlots(1).I = xz;
               imPlots(2).I = yz;
               
               linePlots = csmu.plotBuilders(1, 3);
               for iPlot = 1:length(linePlots)
                  linePlots(iPlot) = copy(linePlotTemplate);
               end
               linePlots(1).X = xDomain;
               linePlots(1).Y = xRange;
               linePlots(2).X = yDomain;
               linePlots(2).Y = yRange;
               linePlots(3).X = zRange;
               linePlots(3).Y = zDomain;
               
               windowLinePlots = csmu.plotBuilders(1, 4);
               for iPlot = 1:length(windowLinePlots)
                  windowLinePlots(iPlot) = copy(windowLinePlotTemplate);
               end
               windowLinePlots(1).X = xz_x_WindowLine(:, 1);
               windowLinePlots(1).Y = xz_x_WindowLine(:, 2);
               windowLinePlots(2).X = xz_z_WindowLine(:, 1);
               windowLinePlots(2).Y = xz_z_WindowLine(:, 2);
               windowLinePlots(3).X = yz_y_WindowLine(:, 1);
               windowLinePlots(3).Y = yz_y_WindowLine(:, 2);
               windowLinePlots(4).X = yz_z_WindowLine(:, 1);
               windowLinePlots(4).Y = yz_z_WindowLine(:, 2);
               
               peakPointPlots = csmu.plotBuilders(1, 3);
               for iPlot = 1:length(peakPointPlots)
                  peakPointPlots(iPlot) = copy(peakPointPlotTemplate);
               end
               peakPointPlots(1).Marker = peakPointMarker.above;
               peakPointPlots(1).X = xPeakDomain;
               peakPointPlots(1).Y = xPeakRange;
               peakPointPlots(2).Marker = peakPointMarker.above;
               peakPointPlots(2).X = yPeakDomain;
               peakPointPlots(2).Y = yPeakRange;
               peakPointPlots(3).Marker = peakPointMarker.left;
               peakPointPlots(3).X = zPeakRange;
               peakPointPlots(3).Y = zPeakDomain;
               
               %%% Text Annotations
               textAnnotations = csmu.plotBuilders(1, 4);
               for iPlot = 1:3
                  textAnnotations(iPlot) = copy(textAnnotationTemplate);
               end
               textAnnotations(1).Text = xAnnotationVerbose;
               textAnnotations(2).Text = yAnnotationVerbose;
               textAnnotations(3).Text = zAnnotationVerbose;
               
               textAnnotations(4) = copy(longTextAnnotationTemplate);
               textAnnotations(4).Text = annotationText;
               
               %%% Arrow Annotations
               aPlots = csmu.plotBuilders(1, 6);
               for iPlot = 1:6
                  aPlots(iPlot) = copy(arrowAnnotationTemplate);
               end
               
               % x left
               aPlots(1).X = xLeftAnnotationDomain;
               aPlots(1).Y = xAnnotationRange;
               aPlots(1).TextArrowString = strcat(xAnnotation, ' ');
               aPlots(1).TextArrowVerticalAlignment = 'middle';
               switch xArrowAnnotationLayout
                  case 'inner'
                     aPlots(1).TextArrowHorizontalAlignment = 'left';
                     
                  case 'outer'
                     aPlots(1).TextArrowHorizontalAlignment = 'right';
                                          
                  otherwise
                     L.error('Unexpected xArrowAnnotationLayout spec: %s', ...
                        xArrowAnnotationLayout);
               end
               
               % x right
               aPlots(2).X = xRightAnnotationDomain;
               aPlots(2).Y = xAnnotationRange;
               
               % y left
               aPlots(3).X = yLeftAnnotationDomain;
               aPlots(3).Y = yAnnotationRange;
               aPlots(3).TextArrowString = strcat(yAnnotation, ' ');               
               aPlots(3).TextArrowVerticalAlignment = 'middle';
               switch yArrowAnnotationLayout
                  case 'inner'
                     aPlots(3).TextArrowHorizontalAlignment = 'left';
                     
                  case 'outer'
                     aPlots(3).TextArrowHorizontalAlignment = 'right';
                     
                  otherwise
                     L.error('Unexpected yArrowAnnotationLayout spec: %s', ...
                        yArrowAnnotationLayout);
               end
               
               % y right
               aPlots(4).X = yRightAnnotationDomain;
               aPlots(4).Y = yAnnotationRange;
               
               % z left (bottom)
               aPlots(5).Y = zLeftAnnotationDomain;
               aPlots(5).X = zAnnotationRange;
               
               % z right (top)
               aPlots(6).Y = zRightAnnotationDomain;
               aPlots(6).X = zAnnotationRange;
               aPlots(6).TextArrowString = zAnnotation;
               switch zArrowAnnotationLayout
                  case 'inner'
                     aPlots(6).TextArrowHorizontalAlignment = 'right';
                     aPlots(6).TextArrowVerticalAlignment = 'top';
                     
                  case 'outer'
                     aPlots(6).TextArrowHorizontalAlignment = 'left';
                     aPlots(6).TextArrowVerticalAlignment = 'bottom';
                     
                  otherwise
                     L.error('Unexpected zArrowAnnotationLayout spec: %s', ...
                        zArrowAnnotationLayout);
               end
               
               %%% Axes Setup
               gs = csmu.GridSpec(3, 5);
               gs.VSpace = 0.3;
               gs.HSpace = 0.3;
               
               axisConfigs(1, 6) = csmu.AxisConfiguration();
               for iAc = 1:length(axisConfigs)
                  axisConfigs(iAc) = copy(axisTemplate);
               end
               
               axisConfigs(1).YAxisLocation = 'right';
               axisConfigs(2).YAxisLocation = 'right';
               
               if doShowHeightAxis
                  axisConfigs(1).YTick = xLabelRange;
                  axisConfigs(2).YTick = yLabelRange;
                  axisConfigs(3).XTick = zLabelRange;
               else
                  axisConfigs(1).YAxis.Visible = 'off';
                  axisConfigs(2).YAxis.Visible = 'off';
                  axisConfigs(3).XAxis.Visible = 'off';
               end
               
               if inputs.DoShowSampleAxis
                  axisConfigs(1).XAxis.Visible = 'on';
                  axisConfigs(2).XAxis.Visible = 'on';
                  axisConfigs(3).YAxis.Visible = 'on';
               else
                  axisConfigs(1).XAxis.Visible = 'off';
                  axisConfigs(2).XAxis.Visible = 'off';
                  axisConfigs(3).YAxis.Visible = 'off';
                  
                  axisConfigs(1).XTick = false;
                  axisConfigs(2).XTick = false;
                  axisConfigs(3).YTick = false;
               end
               
               if inputs.DoShowAxisLabels
                  axisConfigs(1).XLabel.String = 'X';
                  axisConfigs(1).XLabel.VerticalAlignment = 'top';
                  
                  axisConfigs(2).XLabel.String = 'Y';
                  axisConfigs(2).XLabel.VerticalAlignment = 'top';
                  
                  axisConfigs(3).YLabel.String = 'Z';
                  axisConfigs(3).YLabel.Rotation = 0;
                  axisConfigs(3).YLabel.VerticalAlignment = 'middle';
                  axisConfigs(3).YLabel.HorizontalAlignment = 'center';
               else
                  axisConfigs(1).XLabel.String = '';
                  axisConfigs(2).XLabel.String = '';
                  axisConfigs(3).YLabel.String = '';
               end
               
               axisConfigs(1).Position = gs(1, 2:3);
               axisConfigs(1).XLim = xlim;
               axisConfigs(1).YLim = xDisplayRange;
               
               axisConfigs(2).Position = gs(1, 4:5);
               axisConfigs(2).XLim = ylim;
               axisConfigs(2).YLim = yDisplayRange;
               
               axisConfigs(3).Position = gs(2:3, 1);
               axisConfigs(3).YAxisLocation = 'right';
               axisConfigs(3).XDir = 'reverse';
               axisConfigs(3).YLim = zlim;
               axisConfigs(3).XLim = zDisplayRange;
               
               for iAc = 1:2
                  axisConfigs(iAc).XTick = axisConfigs(iAc).XLim;
                  axisConfigs(iAc).XTickLabel = {'', ''};
               end
               axisConfigs(3).YTick = axisConfigs(3).YLim;
               axisConfigs(3).YTickLabel = {'', ''};
               
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
               
               %%% Figure Builder Generation
               subplotStacks = cell(1, 3);
               for iPeak = 1:3
                  subplotStacks{iPeak} = linePlots(iPeak);
                  if self.PeakValid(iPeak)
                     aPlotIdxs = (1:2) + ((iPeak - 1) * 2);
                     
                     subplotStacks{iPeak} = [
                        subplotStacks{iPeak}, ...
                        peakPointPlots(iPeak), ...
                        textAnnotations(iPeak), ...
                        aPlots(aPlotIdxs)];
                  end
               end
               
               fb.PlotBuilders = [...
                  subplotStacks, ...
                  {[imPlots(1), windowLinePlots(1:2)], ...
                  [imPlots(2), windowLinePlots(3:4)], ...
                  textAnnotations(4)}];
               fb.AxisConfigs = axisConfigs;
               figHeight = 800;
               fb.Position = ...
                  [908, 250, (gs.FigureAspectRatio * figHeight), figHeight];
               fb.LinkAxes = {[1 4], 'x'; [2 5], 'x'; [3 4 5], 'y'};
               
            case 2
               %%% Generation of Plot Objects
               imPlots = csmu.plotBuilders(1, 2);
               for iPlot = 1:length(imPlots)
                  imPlots(iPlot) = copy(imPlotTemplate);
               end
               imPlots(1).I = xz;
               imPlots(2).I = xy;
               
               linePlots = csmu.plotBuilders(1, 2);
               for iPlot = 1:length(linePlots)
                  linePlots(iPlot) = copy(linePlotTemplate);
               end
               linePlots(1).Y = zDomain;
               linePlots(1).X = zRange;
               linePlots(2).Y = yDomain;
               linePlots(2).X = yRange;
               
               windowLinePlots = csmu.plotBuilders(1, 2);
               for iPlot = 1:length(windowLinePlots)
                  windowLinePlots(iPlot) = copy(windowLinePlotTemplate);
               end
               windowLinePlots(1).X = xz_z_WindowLine(:, 1);
               windowLinePlots(1).Y = xz_z_WindowLine(:, 2);
               windowLinePlots(2).X = xy_y_WindowLine(:, 1);
               windowLinePlots(2).Y = xy_y_WindowLine(:, 2);
               
               peakPointPlots = csmu.plotBuilders(1, 2);
               for iPlot = 1:length(peakPointPlots)
                  peakPointPlots(iPlot) = copy(peakPointPlotTemplate);
               end
               peakPointPlots(1).Marker = peakPointMarker.right;
               peakPointPlots(1).X = zPeakRange;
               peakPointPlots(1).Y = zPeakDomain;
               peakPointPlots(2).Marker = peakPointMarker.right;
               peakPointPlots(2).X = yPeakRange;
               peakPointPlots(2).Y = yPeakDomain;
               
               %%% Text Annotations
               textAnnotations = csmu.plotBuilders(1, 2);
               for iPlot = 1:length(textAnnotations)
                  textAnnotations(iPlot) = copy(textAnnotationTemplate);
               end
               textAnnotations(1).Text = zAnnotationVerbose;
               textAnnotations(2).Text = yAnnotationVerbose;               
               
               if~isempty(annotationText)
                  L.info(strcat('Long Annotation text cannot be displayed', ...
                     ' with the current plot layout (%d).'), inputs.PlotLayout);
               end
               
               %%% Arrow Annotations
               aPlots = csmu.plotBuilders(1, 4);
               for iPlot = 1:length(aPlots)
                  aPlots(iPlot) = copy(arrowAnnotationTemplate);
               end
               
               % z left (top)
               aPlots(1).Y = zLeftAnnotationDomain;
               aPlots(1).X = zAnnotationRange;
               aPlots(1).TextArrowString = zAnnotation;
               switch zArrowAnnotationLayout
                  case 'inner'
                     aPlots(1).TextArrowHorizontalAlignment = 'left';
                     aPlots(1).TextArrowVerticalAlignment = 'top';
                     
                  case 'outer'
                     aPlots(1).TextArrowHorizontalAlignment = 'right';
                     aPlots(1).TextArrowVerticalAlignment = 'bottom';
                     
                  otherwise
                     L.error('Unexpected zArrowAnnotationLayout spec: %s', ...
                        zArrowAnnotationLayout);
               end
               
               % z right (bottom)
               aPlots(2).Y = zRightAnnotationDomain;
               aPlots(2).X = zAnnotationRange;               
               
               % y left (top)
               aPlots(3).Y = yLeftAnnotationDomain;
               aPlots(3).X = yAnnotationRange;
               aPlots(3).TextArrowString = yAnnotation;
               aPlots(3).TextArrowHorizontalAlignment = 'right';
               aPlots(3).TextArrowVerticalAlignment = 'bottom';
               switch yArrowAnnotationLayout
                  case 'inner'
                     aPlots(3).TextArrowHorizontalAlignment = 'left';
                     aPlots(3).TextArrowVerticalAlignment = 'top';
                     
                  case 'outer'
                     aPlots(3).TextArrowHorizontalAlignment = 'right';
                     aPlots(3).TextArrowVerticalAlignment = 'bottom';
                     
                  otherwise
                     L.error('Unexpected yArrowAnnotationLayout spec: %s', ...
                        yArrowAnnotationLayout);
               end
               
               % y right (bottom)
               aPlots(4).Y = yRightAnnotationDomain;
               aPlots(4).X = yAnnotationRange;              
               
               %%% Axes Setup
               gs = csmu.GridSpec(4, 3);
               gs.VSpace = 0.3;
               gs.HSpace = 0.3;
               
               axisConfigs(1, 4) = csmu.AxisConfiguration();
               for iAc = 1:length(axisConfigs)
                  axisConfigs(iAc) = copy(axisTemplate);
               end                                             
                              
               axisConfigs(1).Position = gs(1:2, 1:2);
               axisConfigs(1).XLim = xlim;
               axisConfigs(1).YLim = zlim;    
               axisConfigs(1).YDir = 'reverse';
               axisConfigs(1).Visible = 'off';               
               
               axisConfigs(2).Position = gs(3:4, 1:2);
               axisConfigs(2).XLim = xlim;
               axisConfigs(2).YLim = ylim;
               axisConfigs(2).YDir = 'reverse';
               axisConfigs(2).Visible = 'off';               
                              
               axisConfigs(3).Position = gs(1:2, 3);
               axisConfigs(3).YLim = zlim;
               axisConfigs(3).YDir = 'reverse';
               axisConfigs(3).XLim = zDisplayRange; 
               axisConfigs(3).XAxisLocation = 'bottom';
               axisConfigs(3).YTick = zlim;
               axisConfigs(3).YTickLabel = {'', ''};               
                              
               axisConfigs(4).Position = gs(3:4, 3);               
               axisConfigs(4).YLim = ylim;
               axisConfigs(4).YDir = 'reverse';
               axisConfigs(4).XLim = yDisplayRange;
               axisConfigs(4).XAxisLocation = 'bottom';               
               axisConfigs(4).YTick = ylim;
               axisConfigs(4).YTickLabel = {'', ''};               
               
               if doShowHeightAxis
                  axisConfigs(3).XTick = zLabelRange;
                  axisConfigs(4).XTick = yLabelRange;
               else
                  axisConfigs(3).XAxis.Visible = 'off';
                  axisConfigs(4).XAxis.Visible = 'off';
               end
               
               if inputs.DoShowSampleAxis
                  axisConfigs(3).YAxis.Visible = 'on';
                  axisConfigs(4).YAxis.Visible = 'on';
               else
                  axisConfigs(3).YAxis.Visible = 'off';
                  axisConfigs(4).YAxis.Visible = 'off';
                  
                  axisConfigs(3).YTick = [];
                  axisConfigs(4).YTick = [];
               end
               
               if inputs.DoShowAxisLabels
                  axisConfigs(3).YLabel.String = 'Z';
                  axisConfigs(3).YLabel.Rotation = 0;
                  axisConfigs(3).YLabel.VerticalAlignment = 'middle';
                  axisConfigs(3).YLabel.HorizontalAlignment = 'center';
                  
                  axisConfigs(4).YLabel.String = 'Y';
                  axisConfigs(4).YLabel.Rotation = 0;
                  axisConfigs(4).YLabel.VerticalAlignment = 'middle';
                  axisConfigs(4).YLabel.HorizontalAlignment = 'center';
               else
                  axisConfigs(3).YLabel.String = '';
                  axisConfigs(4).YLabel.String = '';
               end
               
               %%% Figure Builder Generation
               subplotStacks = cell(1, 2);
               orderToXYZ = [3, 2];
               for iPeak = 1:2
                  subplotStacks{iPeak} = linePlots(iPeak);                  
                  if self.PeakValid(orderToXYZ(iPeak))
                     aPlotIdxs = (1:2) + ((iPeak - 1) * 2);                     
                     subplotStacks{iPeak} = [
                        subplotStacks{iPeak}, ...
                        peakPointPlots(iPeak), ...
                        textAnnotations(iPeak), ...
                        aPlots(aPlotIdxs)];
                  end
               end
               
               fb.PlotBuilders = [...
                  {[imPlots(1), windowLinePlots(1)], ...
                  [imPlots(2), windowLinePlots(2)]}, ...
                  subplotStacks];
               fb.AxisConfigs = axisConfigs;
               figHeight = 800;
               fb.Position = ...
                  [908, 250, (gs.FigureAspectRatio * figHeight), figHeight];
               fb.LinkAxes = {[1 2], 'x'; [1 3], 'y'; [2 4], 'y'};
            
            otherwise
               L.error('Unexpected plot layout passed, %d.', ...
                  inputs.PlotLayout);
         end
      end
   end
   
   methods (Static)
      function resMeasure = calculate(V, point, varargin)
         fcnName = strcat('csmu.', mfilename, '.calculate');
         L = csmu.Logger(fcnName);
         
         %% Parsing Inputs
         L.trace('Parsing inputs');
         ip = csmu.InputParser.fromSpec({
            {'p', 'DoRefinePointBy3DCentroid', false}
            {'p', 'CentroidSearchRadius', []}
            {'p', 'DoRefinePointBy1DPeaks', true}
            {'p', 'Maximum1DRefineIterations', 25}
            {'p', 'Maximum1DPeakDistance', 5}
            {'p', 'PeakLocationReference', 'maximum', {'maximum', 'center'}}
            {'p', 'WidthReference', 'halfheight', {'halfheight', 'halfprom'}}
            {'p', 'FindpeaksArgs', {}}
            {'p', 'BackgroundPrctile', 5}     
            {'p', 'BackgroundValue', []}
            {'p', 'MaximumPeakWidth', inf}
            });
         ip.FunctionName = fcnName;
         ip.parse(varargin{:});
         inputs = ip.Results;
         
         %% Locate Maximum Within Radius
         if inputs.DoRefinePointBy3DCentroid
            L.trace('Attempting to refine point by 3D centroid estimation');
            
            searchRadius = inputs.CentroidSearchRadius;
            if isempty(searchRadius)
               % default search radius (in voxels) is 5% of the largest 
               % dimension of the input volume V
               searchRadius = ceil(0.05 * max(size(V)));
            end
            
            windowSideLength = (2 * searchRadius) + 1;
            windowSize = repmat(windowSideLength, 1, 3);
            lims = csmu.ImageRef(windowSize);
            lims.zeroCenter;
            limShiftTransform = csmu.Transform;
            limShiftTransform.TranslationRotationOrder = csmu.IndexOrdering.XY;
            limShiftTransform.Translation = point;
            lims = limShiftTransform.warpRef(lims);
            vWindowed = csmu.changeView(V, csmu.ImageRef(V), lims);
            % [maxVal, maxIdx] = max(vWindowed(:));
            threshVal = prctile(vWindowed, 95, 'all');
            vWindowedThresh = (vWindowed >= threshVal);
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
            
            if ~any(isnan(newPoint))
               L.trace(['Point has been updated to [%s] from [%s],\n\ta ', ...
                  'distance of %.1f volxels apart.'], num2str(newPoint), ...
                  num2str(point), candidateDistance);
               point = newPoint;
            end
         end
         
         %% Generating Line and View         
         findPeaksArgs = [
            {'WidthReference', inputs.WidthReference}, ...
            inputs.FindpeaksArgs];         
         
         L.trace('\tGenerating Line Samples');
         peakPoint = point;         
         
         L.trace('\tDetermining Peak Locations');
         iIter = 0;
         while true
            [xl, yl, zl] = csmu.arrayLineSample(V, peakPoint);
            
            if isempty(inputs.BackgroundValue)
               peakBackground = prctile(...
                  cat(1, xl, yl, zl), ...
                  inputs.BackgroundPrctile, ...
                  'all');               
               L.trace('%d - Peak background found to be %.1f', ...
                  iIter, peakBackground)
            else
               peakBackground = inputs.BackgroundValue;
            end
                        
            xlMax = max(xl, [], 'all');
            [xPeakVals, xLocs, xWGuesses, xPs] = ...
               findpeaks(xl / xlMax, findPeaksArgs{:});
            xPeakVals = xPeakVals * xlMax;
            xPs = xPs * xlMax;
            
            ylMax = max(yl, [], 'all');
            [yPeakVals, yLocs, yWGuesses, yPs] = ...
               findpeaks(yl / ylMax, findPeaksArgs{:});
            yPeakVals = yPeakVals * ylMax;
            yPs = yPs * ylMax;
            
            zlMax = max(zl, [], 'all');
            [zPeakVals, zLocs, zWGuesses, zPs] = ...
               findpeaks(zl / zlMax, findPeaksArgs{:});
            zPeakVals = zPeakVals * zlMax;
            zPs = zPs * zlMax;
            
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
               xWidth = diff(xEdges);
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  if any(isnan(xEdges))
                     if all(isnan(xEdges))
                        % do nothing
                     elseif isnan(xEdges(1))
                        xEdgesTemp = [0.5, xEdges(2)];
                        xWidth = diff(xEdgesTemp);
                        xLoc = mean(xEdgesTemp);
                     else
                        xEdgesTemp = [xEdges(1), length(xl) + 0.5];
                        xWidth = diff(xEdgesTemp);
                        xLoc = mean(xEdgesTemp);
                     end                  
                  else
                     xLoc = mean(xEdges);
                  end
                  
                  xSqD = (xLoc - peakPoint(1)) .^ 2;
               end
               
               xValid = (sqrt(xSqD) <= inputs.Maximum1DPeakDistance) ...
                  && (xWidth <= inputs.MaximumPeakWidth) ...
                  && ~any(isnan(xEdges));
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
               yWidth = diff(yEdges);
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  yLoc = mean(yEdges);
                  ySqD = (yLoc - peakPoint(2)) .^ 2;
               end
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  if any(isnan(yEdges))
                     if all(isnan(yEdges))
                        % do nothing
                     elseif isnan(yEdges(1))
                        yEdgesTemp = [0.5, yEdges(2)];
                        yWidth = diff(yEdgesTemp);
                        yLoc = mean(yEdgesTemp);
                     else
                        yEdgesTemp = [yEdges(1), length(yl) + 0.5];
                        yWidth = diff(yEdgesTemp);
                        yLoc = mean(yEdgesTemp);
                     end                  
                  else
                     yLoc = mean(yEdges);
                  end
                  
                  ySqD = (yLoc - peakPoint(2)) .^ 2;
               end
               
               yValid = (sqrt(ySqD) <= inputs.Maximum1DPeakDistance) ...
                  && (yWidth <= inputs.MaximumPeakWidth) ...
                  && ~any(isnan(yEdges));
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
               zWidth = diff(zEdges);
               
               if strcmpi(inputs.PeakLocationReference, 'center')
                  if any(isnan(zEdges))
                     if all(isnan(zEdges))
                        % do nothing
                     elseif isnan(zEdges(1))
                        zEdgesTemp = [0.5, zEdges(2)];
                        zWidth = diff(zEdgesTemp);
                        zLoc = mean(zEdgesTemp);
                     else
                        zEdgesTemp = [zEdges(1), length(zl) + 0.5];
                        zWidth = diff(zEdgesTemp);
                        zLoc = mean(zEdgesTemp);
                     end
                  else
                     zLoc = mean(zEdges);
                  end
                  
                  zSqD = (zLoc - peakPoint(3)) .^ 2;
               end
               
               zValid = (sqrt(zSqD) <= inputs.Maximum1DPeakDistance) ...
                  && (zWidth <= inputs.MaximumPeakWidth) ...
                  && ~any(isnan(zEdges));
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
                  
                  L.trace(strcat(...
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
                     L.trace('Maximum iterations reached, breaking loop.');
                     break                     
                  else
                     iIter = iIter + 1;
                     continue
                  end
               else                  
                  L.trace(strcat(...
                     'Peak point found to be\n[%s]; sample point is\n[%s].', ...
                     ' Distance between them is %.1f voxels.'), ...
                     num2str(peakPoint), ...
                     num2str(point), ...
                     rawDelta);
                  break
               end
            else
               L.trace(strcat('Peaks were not found in all dimensions ', ...
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
         L = csmu.Logger('edgeHelper');
         
         inputs.WindowSize = 1;
         inputs.MaxFraction = 0.5;
         
         intensity = intensity - background;  
         inputLength = length(intensity);
         
         searchIntensity = movmean(...
            intensity, ...
            inputs.WindowSize, ...
            'Endpoints', 'shrink');
         
         if csmu.isint(loc)
            maxIdx = loc;
         else
            testLocs = [...
               csmu.bound(ceil(loc), 1, inputLength), ...
               csmu.bound(floor(loc), 1, inputLength)];
            [~, tempMaxIdx] = max(...
               searchIntensity(testLocs), [], 'all', 'linear');
            maxIdx = testLocs(tempMaxIdx);
         end         
         
         widthValue = searchIntensity(maxIdx) * inputs.MaxFraction;
         
         %%% Find the Leading Edge            
         searchIdx = maxIdx;         
         isLeadingEdge = true;
         while searchIdx > 1
            if searchIntensity(searchIdx - 1) < widthValue
               isLeadingEdge = false;
               break
            else
               searchIdx = searchIdx - 1;
            end
         end
        
         if isLeadingEdge
            L.warn(strcat('Leading edge of peak is beyond boundary of', ...
               ' array, assigning NaN for leading edge.'));
            leadingEdgeLoc = NaN;
         else
            leadingEdgeTestLocs = csmu.bound(...
               [-1, 0] + searchIdx, 1, inputLength);
            leadingEdgeTestVals = searchIntensity(leadingEdgeTestLocs);
            leadingEdgeLoc = interp1(...
               leadingEdgeTestVals, ...
               leadingEdgeTestLocs, ...
               widthValue);
         end
         
         %%% Find the Trailing Edge
         searchIdx = maxIdx;
         isTrailingEdge = true;
         while searchIdx < inputLength
            if searchIntensity(searchIdx + 1) < widthValue
               isTrailingEdge = false;
               break
            else
               searchIdx = searchIdx + 1;
            end
         end
         
         if isTrailingEdge
            L.warn(strcat('Trailing edge of peak is beyond boundary', ...
               ' of array, assigning NaN for trailing edge.'));
            trailingEdgeLoc = NaN;
         else
            trailingEdgeTestLocs = csmu.bound(...
               [0, 1] + searchIdx, 1, inputLength);
            trailingEdgeTestVals = searchIntensity(trailingEdgeTestLocs);
            trailingEdgeLoc = interp1(...
               trailingEdgeTestVals, ...
               trailingEdgeTestLocs, ...
               widthValue);
         end
         
         varargout = {
            [leadingEdgeLoc, trailingEdgeLoc], ...
            widthValue + background};
         
%          intensity = intensity - background;
%          intensity(intensity < 0) = 0;
%          peak = peak - background;
%          
%          lims = [1, length(intensity)];
%          halfWide = ceil(width / 2);
%          searchWidth = max(2, halfWide);
%          halfPeak = peak / 2;
%          
%          leftSearch = colon(...
%             round(csmu.bound((loc - (halfWide / 2)) - (searchWidth / 2), ...
%             lims(1), lims(2))), ...
%             round(csmu.bound((loc - (halfWide / 2)) + (searchWidth / 2), ...
%             lims(1), lims(2))));
%          leftIntensity = intensity(leftSearch);
%          
%          if true
%             while true
%                leftNonPeakMask = leftIntensity < halfPeak;
%                leftNonPeakSearch = leftSearch(leftNonPeakMask);
%                
%                if any(leftNonPeakSearch)
%                   break
%                else
%                   leftSearch = leftSearch - 1;
%                   leftIntensity = intensity(leftSearch);
%                end
%             end
%             
%             leftSearch = (0:1) + leftNonPeakSearch(end);
%             leftIntensity = intensity(leftSearch);
%          end
%          
%          rightSearch = colon(...
%             round(csmu.bound((loc + (halfWide / 2)) - (searchWidth / 2), ...
%             lims(1), lims(2))), ...
%             round(csmu.bound((loc + (halfWide / 2)) + (searchWidth / 2), ...
%             lims(1), lims(2))));
%          rightIntensity = intensity(rightSearch);
%          
%          
%          if true
%             while true
%                rightNonPeakMask = rightIntensity < halfPeak;
%                rightNonPeakSearch = rightSearch(rightNonPeakMask);
%                
%                if any(rightNonPeakSearch)
%                   break
%                else
%                   rightSearch = rightSearch + 1;
%                   rightIntensity = intensity(rightSearch);
%                end
%             end
%             
%             rightSearch = (-1:0) + rightNonPeakSearch(1);
%             rightIntensity = intensity(rightSearch);
%          end
%          
%          leftEdge = interp1(leftIntensity, leftSearch, halfPeak);
%          rightEdge = interp1(rightIntensity, rightSearch,  halfPeak);
%          
%          assert(~any(isnan([leftEdge, rightEdge])));
%          
%          varargout = {
%             [leftEdge, rightEdge], background + halfPeak};
      end
   end
end