function addProjViewLabels(ax, bounds, varargin)

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
   
   quiver(ax, quiverPos{:}, 'Color', mainColor, 'LineWidth', 2, ...
      'MaxHeadSize', 0.5, 'AutoScale', 'off');
   
   horzTextPos = {horzArrowPos{1}(1) + arrowLength ...
      * (1 + textOffsetFraction), horzArrowPos{2}(1)};
   vertTextPos = {vertArrowPos{1}(1), ...
      vertArrowPos{2}(1) + arrowLength * (1 + textOffsetFraction)};
   
   textArgs = {'Color', mainColor, 'FontWeight', 'bold'};
   text(ax, horzTextPos{:}, axlabel{iView, 1},'VerticalAlignment', 'middle', ...
      'HorizontalAlignment', 'left', textArgs{:});
   text(ax, vertTextPos{:}, axlabel{iView, 2},'VerticalAlignment', 'top', ...
      'HorizontalAlignment', 'center', textArgs{:});
end