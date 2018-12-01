function plotBuilders = addProjViewLabels(bounds, varargin)

ip = inputParser;
ip.addParameter('Color', 'k');
ip.parse(varargin{:});
mainColor = ip.Results.Color;

allSizes = [];
for iView = 1:3
   b = bounds{iView};
   newSizes = b(2, [2 1]) - b(1, [2 1]);
   allSizes = [allSizes, newSizes(:)'];
end
axlabel = {'X', 'Y'; 'X', 'Z'; 'Z', 'Y'};
allSizes = unique(allSizes);
minDimSizes = min(allSizes);
arrowLength = min(minDimSizes * 0.6, max(allSizes) * 0.2);
arrowMargin = minDimSizes * 0.06;
arrowOrigin = minDimSizes * 0.06;
textOffsetFraction = .02;


plotBuilders = cell(1, 9);
for iView = 1:3
   b = bounds{iView};
   horzArrowPos = {b(1, 2) + [arrowMargin, arrowMargin + arrowLength], ...
      b(1, 1) + [arrowOrigin, arrowOrigin]};
   vertArrowPos = {b(1, 2) + [arrowOrigin, arrowOrigin], ...
      b(1, 1) + [arrowMargin, arrowMargin + arrowLength]};
   
   quiverPos = { ...
      [horzArrowPos{1}(1), vertArrowPos{1}(1)], ...
      [horzArrowPos{2}(1), vertArrowPos{2}(1)], ...
      [arrowLength,        0], ...
      [0,                  arrowLength]};
   
   qp = utils.QuiverPlot;
   [qp.X, qp.Y, qp.U, qp.V] = quiverPos{:};
   qp.Color = mainColor;
   qp.LineWidth = 2;
   qp.MaxHeadSize = 0.5;
   qp.AutoScale = 'off';
   
   horzTextPos = {horzArrowPos{1}(1) + arrowLength ...
      * (1 + textOffsetFraction), horzArrowPos{2}(1)};
   vertTextPos = {vertArrowPos{1}(1), ...
      vertArrowPos{2}(1) + arrowLength * (1 + textOffsetFraction)};
   
   tpHorz = utils.TextPlot;
   tpHorz.Color = mainColor;
   tpHorz.FontWeight = 'bold';
   
   [tpHorz.X, tpHorz.Y] = horzTextPos{:};
   tpHorz.Text = axlabel{iView, 1};
   tpHorz.VerticalAlignment = 'middle';
   tpHorz.HorizontalAlignment = 'left';
   
   tpVert = copy(tpHorz);
   [tpVert.X, tpVert.Y] = vertTextPos{:};
   tpVert.Text = axlabel{iView, 2};
   tpVert.VerticalAlignment = 'top';
   tpVert.HorizontalAlignment = 'center';
   
   sel = zeros(1, 2);
   sel(1) = ((iView - 1) * 3) + 1;
   sel(2) = sel(1) + 2;
   plotBuilders(sel(1):sel(2)) = {qp, tpHorz, tpVert};
end