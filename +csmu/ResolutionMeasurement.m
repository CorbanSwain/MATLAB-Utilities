classdef ResolutionMeasurement < csmu.Object
   properties
      ImageRef csmu.ImageRef
      Position
      IntensityLines
      PeakPosition
      PeakWidth
      PeakProminance
      PeakValue
      Index
      Image
   end
      
   methods
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
   end
      
   methods (Static)
      function resMeasure = calculate(V, point, varargin)        
         L = csmu.Logger(mfilename);
         
         %% Parsing Inputs
         L.info('Parsing inputs');
         ip = inputParser;
         ip.addParameter('MaximumRadius', []);         
         ip.addParameter('MinPeakDistance', []);
         ip.addParameter('MinPeakProminence', []);
         ip.parse(varargin{:});
         minPeakDistance = ip.Results.MinPeakDistance;
         minPeakProminence = ip.Results.MinPeakProminence;
         maximumRadius = ip.Results.MaximumRadius;
         
         %% Locate Maximum Within Radius
         if ~isempty(maximumRadius)
            windowSideLength = (2 * maximumRadius) + 1;
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
            volumeSpaceTransform = csmu.Transform; 
            
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
         L = csmu.Logger(mfilename);
         L.info('\tGenerating Line Samples');
         [xl, yl, zl] = csmu.arrayLineSample(V, point);
         
         L.info('\tDetermining Peak Locations');
         findPeaksArgs = {'WidthReference', 'halfprom'};
         if ~isempty(minPeakDistance)
            findPeaksArgs = [findPeaksArgs, {'MinPeakDistance', ...
               minPeakDistance}];
         end
         if ~isempty(minPeakProminence)
            findPeaksArgs = [findPeaksArgs, {'MinPeakProminence', ...
               minPeakProminence}];
         end
         
         [xPeaks, xLocs, xW, xP] = findpeaks(xl, findPeaksArgs{:});
         [yPeaks, yLocs, yW, yP] = findpeaks(yl, findPeaksArgs{:});
         [zPeaks, zLocs, zW, zP] = findpeaks(zl, findPeaksArgs{:});
         
         % Get the index of the peak closest to the target point
         [~, xIdx] = min((xLocs - point(1)) .^ 2);
         [~, yIdx] = min((yLocs - point(2)) .^ 2);
         [~, zIdx] = min((zLocs - point(3)) .^ 2);
         
         resMeasure = csmu.ResolutionMeasurement;
         resMeasure.Image = V;
         resMeasure.ImageRef = csmu.ImageRef(V);
         resMeasure.Position = point;
         resMeasure.IntensityLines = {xl,           yl,           zl};
         resMeasure.PeakPosition =   [xLocs(xIdx),  yLocs(yIdx),  zLocs(zIdx)];
         resMeasure.PeakWidth =      [xW(xIdx),     yW(yIdx),     zW(zIdx)];
         resMeasure.PeakProminance = [xP(xIdx),     yP(yIdx),     zP(zIdx)];
         resMeasure.PeakValue =      [xPeaks(xIdx), yPeaks(yIdx), zPeaks(zIdx)];
      end
   end            
end