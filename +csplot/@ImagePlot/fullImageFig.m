function fb = fullImageFig(I)
ISize = size(I);
IAspectRatio = ISize(1) / ISize(2);
defaultSize = 1000;

axc = csplot.AxisConfiguration;
axc.XLim = [0.5, 0.5 + ISize(2)];
axc.YLim = [0.5, 0.5 + ISize(1)];
axc.YDir = 'reverse';
axc.Visible = 'off';
axc.ActivePositionProperty = 'position';
axc.Units = 'normalized';
axc.Position = [0 0 1 1];
axc.DataAspectRatio = [1 1 1];
axc.DataAspectRatioMode = 'manual';

fb = csplot.FigureBuilder;
fb.Position = [0, 0, defaultSize, defaultSize * IAspectRatio];
fb.AxisConfigs = {axc};
end