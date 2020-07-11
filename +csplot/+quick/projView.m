function fb = projView(V, varargin)
ip = inputParser;
ip.addParameter('ImageRef', []); % listable
ip.addParameter('BackgroundColor', []);
ip.addParameter('AxesColor', []);
ip.addParameter('Colormap', 'magma'); % listable
ip.addParameter('ColorLimits', []); % listable
ip.addParameter('DoShowFigure', true);
ip.addParameter('AxesArgs', {});
ip.addParameter('ScaleBarLength', []);
ip.addParameter('DoShowAxesArrows', false);
ip.addParameter('DoShowAxes', true);
ip.addParameter('DoConvertToRGB', false);
ip.addParameter('UnitRatio', 1, @(x) isvector(x) && any(length(x) == [1 3]));
ip.addParameter('UnitRatioOrdering', csmu.IndexOrdering.XY, ...
   @(x) isa(x, 'csmu.IndexOrdering'))
ip.addParameter('DarkMode', false);
ip.addParameter('DoMaskDark', false);
ip.addParameter('FigureName', '');
ip.addParameter('UnitName', '');
ip.addParameter('ExportOptions', {});
ip.addParameter('SaveDirectory', '');
ip.addParameter('DoCloseFigure', false);
ip.addParameter('AnnotationText', '');
ip.parse(varargin{:});
ip = ip.Results;
cmapName = ip.Colormap;
clims = ip.ColorLimits;
doShowFigure = ip.DoShowFigure;
imageRef = ip.ImageRef;
axesArgs = ip.AxesArgs;
unitRatio = ip.UnitRatio;
unitName = ip.UnitName;
unitRatioOrdering = ip.UnitRatioOrdering;
backgroundColor = ip.BackgroundColor;
axesColor = ip.AxesColor;
doDarkMode = ip.DarkMode;
scaleBarLength = ip.ScaleBarLength;
doShowAxes = ip.DoShowAxes;
doShowAxesArrows = ip.DoShowAxesArrows;
figureName = ip.FigureName;
doConvertToRGB = ip.DoConvertToRGB;
doMaskDark = ip.DoMaskDark;
saveDir = ip.SaveDirectory;
doCloseFigure = ip.DoCloseFigure;
annotationText = ip.AnnotationText;
exportOptions = ip.ExportOptions;

L = csmu.Logger(strcat('csplot.quick.', mfilename));

if doDarkMode
   if isempty(backgroundColor)
      backgroundColor = ones(1, 3) * 0.05;
   end
   if isempty(axesColor)
      axesColor = ones(1, 3) * 0.75;
   end
end

if isa(V, 'csmu.Image') && ~isscalar(V)
   V = num2cell(V(:));
elseif ~iscell(V)
   V = csmu.tocell(V);
end
numVolumes = length(V);

for iVol = 1:numVolumes
   V{iVol} = csmu.Image(V{iVol});
end

if iscell(cmapName)
   L.assert(length(cmapName) >= numVolumes);
else
   cmapTemp = cmapName;
   cmapName = cell(1, numVolumes);
   [cmapName{:}] = deal(cmapTemp);
end

if iscell(clims)
   L.assert(length(cmapName) == numVolumes);
else
   climsTemp = clims;
   clims = cell(1, numVolumes);
   [clims{:}] = deal(climsTemp);
end

if iscell(imageRef)
   L.assert(length(imageRef) == numVolumes);
   for iRef = 1:numVolumes
      imageRef{iRef} = csmu.ImageRef(imageRef{iRef});
   end
else
   if isempty(imageRef)
      imageRef = cell(1, numVolumes);
      for iRef = 1:numVolumes
         if isscalar(unitRatio)
            unitRatio = [1 1 1] * unitRatio;
         else
            unitRatio = unitRatioOrdering.toXY(unitRatio, ...
               csmu.IndexType.VECTOR);
         end
         imageRef{iRef} = csmu.ImageRef(size(V{iRef}.I), unitRatio(1), ...
            unitRatio(2), unitRatio(3));
      end
   elseif isa(imageRef, 'csmu.ImageRef')
      if isscalar(imageRef)
         refTemp = imageRef;
         imageRef = cell(1, numVolumes);
         [imageRef{:}] = deal(refTemp);
      else
         imageRef = num2cell(imageRef(:));
         L.assert(length(imageRef) == numVolumes);
      end
   else
      refTemp = csmu.ImageRef(imageRef);
      imageRef = cell(1, numVolumes);
      [imageRef{:}] = deal(refTemp);
   end
end

combinedRef = csmu.computeMutualRef(imageRef, 'Method', 'Max');
 
imagePlots = csplot.ImagePlot(numVolumes, 3);
for iVol = 1:numVolumes
   imagePlots(iVol, [1, 2]).X = imageRef{iVol}.XPixelCenterLimits;
   imagePlots(iVol, [1, 3]).Y = imageRef{iVol}.YPixelCenterLimits;
   imagePlots(iVol, 2).Y = imageRef{iVol}.ZPixelCenterLimits;
   imagePlots(iVol, 3).X = imageRef{iVol}.ZPixelCenterLimits;
   [imagePlots(iVol, :).I] = deal(V{iVol}.XYProjection, ...
      V{iVol}.XZProjection, V{iVol}.YZProjection);
   if doMaskDark
      [imagePlots(iVol, :).AlphaData] = ...
         deal(V{iVol}.XYProjection, V{iVol}.XZProjection, ...
         V{iVol}.YZProjection);
   end
   imagePlots(iVol, :).Colormap = cmapName{iVol};
   imagePlots(iVol, :).ColorLimits = clims{iVol};
end
imagePlots.DoConvertToRGB = doConvertToRGB;

if ~any(strcmpi('UnitName', axesArgs)) && ~isempty(unitName)
   axesArgs = [axesArgs, {'UnitName', unitName}];
end

if ~doShowAxes && ~any(strcmpi('MarginUnits', axesArgs))
   marginParams = {'Top', 'Bottom', 'Left', 'Right'};
   marginVal = 0.01;
   for iParam = 1:length(marginParams)
      pName = marginParams{iParam};
      if ~any(strcmpi(pName, axesArgs))
         axesArgs = [axesArgs, {pName, marginVal}];
      end
   end   
end

[axisConfigs, gs] = csplot.quick.projViewAxes(combinedRef, axesArgs{:});

if ~doShowAxes
   axisConfigs.XColor = 'none';
   axisConfigs.YColor = 'none';
   axisConfigs.ZColor = 'none';
else
   axisConfigs.XColor = axesColor;
   axisConfigs.YColor = axesColor;
   axisConfigs.ZColor = axesColor;
end
axisConfigs.Color = 'k';

fb = csplot.FigureBuilder;
figureHeight = 1100;
fb.Position = [100, 100, figureHeight * gs.FigureAspectRatio, figureHeight];
fb.AxisConfigs = axisConfigs;

fb.LinkAxes = {[1, 2], 'X'; [1 3], 'Y'; [2, 3], {'Y', 'X'}; [3, 2], {'X', 'Y'}};
fb.PlotBuilders = {num2cell(imagePlots(:, 1)), ...
   num2cell(imagePlots(:, 2)), num2cell(imagePlots(:, 3)), {}};
fb.Color = backgroundColor;
if~isempty(figureName)
   fb.Name = figureName;
end

if ~isempty(scaleBarLength)
   xlim = combinedRef.XWorldLimits;
   ylim = combinedRef.YWorldLimits;
   ypos = ones(1, 2) * (ylim(1) + diff(ylim) * 0.95);
   xpos = [-scaleBarLength, 0] + (xlim(1) + diff(xlim) * 0.95);
   line = csplot.LineBuilder;
   line.X = xpos;
   line.Y = ypos;
   line.LineWidth = 4;
   line.Color = 'w';
   
   textMargin = 0.01;
   textPlot = csplot.TextPlot;
   textPlot.Text = sprintf('%d %s', scaleBarLength, unitName);
   textPlot.X = mean(xpos);
   textPlot.Y = ypos(1) + (textMargin * diff(ylim));
   textPlot.Color = 'w';
   textPlot.VerticalAlignment = 'top';
   textPlot.HorizontalAlignment = 'center'; 
   textPlot.FontWeight = 'bold';
   fb.PlotBuilders{1} = [fb.PlotBuilders{1}, {line, textPlot}];
end

if doShowAxesArrows
   arrowLen = min(cellfun(@(lims) diff(lims), combinedRef.WorldLimits)) * 0.15;
   arrowStart = arrowLen * 0.25;
   quiverPlots = csplot.QuiverPlot(1, 4); % x, y, z(x), z(y)
   quiverPlots.X = arrowStart;
   quiverPlots.Y = arrowStart;
   quiverPlots([1, 3]).U = arrowLen;
   quiverPlots([1, 3]).V = 0;
   quiverPlots([2, 4]).U = 0;
   quiverPlots([2, 4]).V = arrowLen;
   quiverPlots.Color = 'w';
   quiverPlots.LineWidth = 1.5;
   quiverPlots.MaxHeadSize = 0.7;
   quiverPlots.AutoScale = 'off';
   quiverPlots.Marker = '.';
   quiverPlots.MarkerSize = quiverPlots(1).LineWidth * 3;
   
   textMargin = arrowLen * 0.2;
   textPlots = csplot.TextPlot(1, 4); % x, y, z(x), z(y)
   textPlots([1, 3]).X = arrowStart + arrowLen + textMargin;
   textPlots([1, 3]).Y = arrowStart;
   textPlots([2, 4]).X = arrowStart;
   textPlots([2, 4]).Y = arrowStart + arrowLen + textMargin;
   textPlots(1).Text = 'X';
   textPlots(2).Text = 'Y';
   textPlots(3:4).Text = 'Z';
   textPlots.Color = 'w';
   textPlots.FontWeight = 'bold';
   textPlots.VerticalAlignment = 'middle';
   textPlots.HorizontalAlignment = 'center';      
   
   fb.PlotBuilders{1} = [fb.PlotBuilders{1}, num2cell(quiverPlots([1, 2])), ...
      num2cell(textPlots([1, 2]))];
   fb.PlotBuilders{2} = [fb.PlotBuilders{2}, num2cell(quiverPlots([1, 4])), ...
      num2cell(textPlots([1, 4]))];
   fb.PlotBuilders{3} = [fb.PlotBuilders{3}, num2cell(quiverPlots([2, 3])), ...
      num2cell(textPlots([2, 3]))];   
end

if ~isempty(annotationText)
   textPlot = csplot.TextPlot;
   textPlot.Text = annotationText;
   textPlot.X = 0;
   textPlot.Y = 1;
   if doDarkMode
      textPlot.Color = axesColor;
   end
   textPlot.Units = 'normalized';
   textPlot.FontSize = 8.5;
   textPlot.FontName = 'input';
   textPlot.VerticalAlignment = 'top';
   textPlot.Interpreter = 'none';
   fb.PlotBuilders{4} = [fb.PlotBuilders{4}, {textPlot}];
end

if doShowFigure
   fb.show();
end

if ~isempty(saveDir)
   fb.save(saveDir, 'ExportOptions', exportOptions);
end

if doCloseFigure
   fb.close();
end
end