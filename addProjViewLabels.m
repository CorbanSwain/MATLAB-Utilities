function addProjViewLabels(fig, ax, bounds, varargin)

axlabel = {'X', 'Y'; 'X', 'Z'; 'Z', 'Y'};
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
allSizes = unique(allSizes);
minDimSizes = min(allSizes);
arrowLength = min(minDimSizes * 0.6, max(allSizes) * 0.2);
arrowMargin = minDimSizes * - 0.18;
arrowOrigin = minDimSizes * -0.05;

for iView = 1:3
   b = bounds{iView};
   arrow1Pos = {b(1, 2) + [arrowMargin, arrowMargin + arrowLength], ...
      b(1, 1) + [arrowOrigin, arrowOrigin]};
   arrow2Pos = {b(1, 2) + [arrowOrigin, arrowOrigin], ...
      b(1, 1) + [arrowMargin, arrowMargin + arrowLength]};
   
   [arrow1Pos{:}] = utils.du2fu(ax, arrow1Pos{:});
   [arrow2Pos{:}] = utils.du2fu(ax, arrow2Pos{:});

   annotationArgs= {'Color', mainColor, 'HeadStyle', 'cback2'};
   
   annotation(fig, 'textarrow', arrow1Pos{:}, annotationArgs{:}, 'String', ...
      axlabel{iView, 1}, 'VerticalAlignment', 'middle', ...
      'HorizontalAlignment', 'left');
   annotation(fig, 'textarrow', arrow2Pos{:}, annotationArgs{:}, 'String', ...
      axlabel{iView, 2}, 'VerticalAlignment', 'bottom', ...
      'HorizontalAlignment', 'center');
end