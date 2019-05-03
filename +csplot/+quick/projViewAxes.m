function [axisConfigs, gs] = projViewAxes(imageRef, varargin)
%% Parse Inputs
imageRef = csmu.ImageRef(imageRef);

ip = inputParser;
ip.addParameter('Top', 0.1);
ip.addParameter('Bottom', 0.01);
ip.addParameter('Left', 0.1);
ip.addParameter('Right', 0.01);
ip.addParameter('Gap', 0.02); 
% relative - the values provided represent fractions of the longest
%            dimension in the image (as specified by the images "world 
%            extents");
% absolute - the values provided specify measurements in "world units"
%            (e.g. voxels).
ip.addParameter('MarginUnits', 'Relative', ...
   @(x) any(strcmpi(x, {'Relative', 'Absolute'})));
ip.addParameter('UnitName', 'voxels');
ip.addParameter('UnitFormat', ', %s');

ip.parse(varargin{:});
ip = ip.Results;
mTop = ip.Top;
mBottom = ip.Bottom;
mLeft = ip.Left;
mRight = ip.Right;
mGap = ip.Gap;
mUnits = lower(ip.MarginUnits);
unitName = ip.UnitName;
unitFmt = ip.UnitFormat;
if isempty(mGap)
   switch mUnits
      case 'relative'
         mGap = 0.05;
      case 'absolute'
         mGap = 10;
   end
end
margins = [mTop, mBottom, mLeft, mRight, mGap];

%% Compute GridSpec Dimensions
dimMin = cellfun(@(lims) lims(1), imageRef.WorldLimits);
dimMax = cellfun(@(lims) lims(2), imageRef.WorldLimits);
dimLensRaw = dimMax - dimMin;
discretizationFactor = 2048 / min(dimLensRaw);
dimLens = ceil(dimLensRaw * discretizationFactor);
dimLensOrder = csmu.IndexOrdering.XY;

switch mUnits
   case 'relative'
      maxDimLength = max(dimLens);
      margins = round(margins * maxDimLength);
      
   case 'absolute'
      margins = round(margins * discretizationFactor);
end

gridSpecSize = [dimLens(2) + sum(margins(1:2)), dimLens(1) ...
   + sum(margins(3:4))] + dimLens(3) + margins(5);
gs = csplot.GridSpec(gridSpecSize, 'VSpace', 0, 'HSpace', 0, 'Top', 0, ...
   'Bottom', 0, 'Left', 0, 'Right', 0);

%% Generate Axes
axisConfigs = csplot.AxisConfiguration(1, 4);

gridSpecSubs = ...
   { ...
    {(1:dimLens(2)) + margins(1), ...
     (1:dimLens(1)) + margins(3)}, ...
    {(1:dimLens(3)) + margins(1) + margins(5) + dimLens(2), ...
     (1:dimLens(1)) + margins(3)}, ...
    {(1:dimLens(2)) + margins(1), ...
     (1:dimLens(3)) + margins(3) + margins(5) + dimLens(1)}, ...
    {(1:dimLens(3)) + margins(1) + margins(5) + dimLens(2), ...
     (1:dimLens(3)) + margins(3) + margins(5) + dimLens(1)}};

for iAxis = 1:length(axisConfigs)
   axisConfigs(iAxis).Position = gs(gridSpecSubs{iAxis}{:});   
end

%%% set axis limits
axisConfigs([1, 2]).XLim = [dimMin(1), dimMax(1)];
axisConfigs([1, 3]).YLim = [dimMin(2), dimMax(2)];
axisConfigs(2).YLim = [dimMin(3), dimMax(3)];
axisConfigs(3).XLim = axisConfigs(2).YLim;

%%% reverse z-axis + y-axis
axisConfigs([1, 3]).YDir = 'reverse';
axisConfigs(3).XDir = 'reverse';

%%% set axis locations1
axisConfigs([1, 3]).XAxisLocation = 'top';
axisConfigs([1, 2]).YAxisLocation = 'left';

%%% set axis visibility
axisConfigs(4).Visible = 'off';
axisConfigs(2).XAxis.Visible = 'off';
axisConfigs(3).YAxis.Visible = 'off';

%%% set axis labels
axisConfigs(1).XLabel = strcat('X', sprintf(unitFmt, unitName));
axisConfigs(1).YLabel = strcat('Y', sprintf(unitFmt, unitName));
axisConfigs(2).YLabel = strcat('Z', sprintf(unitFmt, unitName));
axisConfigs(3).XLabel = strcat('Z', sprintf(unitFmt, unitName));

%%% set axis font properties
axisConfigs.FontSize = 10;

%%% set tick properties
axisConfigs.TickDir = 'out';

%%% set axis Ratio
% axisConfigs.PlotBoxAspectRatioMode = 'manual';
% [axisConfigs(1:3).PlotBoxAspectRatio] = deal([dimLens([1, 2]), 1], ...
%    [dimLens([1, 3]), 1], [dimLens([3, 2]), 1]);

%%% set limit mode
% axisConfigs.XLimMode = 'auto';
% axisConfigs.YLimMode = 'auto';
% axisConfigs.ZLimMode = 'auto';
end
