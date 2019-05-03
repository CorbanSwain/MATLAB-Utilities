function fb = projView(V, varargin)
imageRef = csmu.ImageRef(V);
V = csmu.Image(V);

imagePlots = csplot.ImagePlot(1, 3);
imagePlots(1).X = imageRef.XPixelCenterLimits;
imagePlots(2).X = imageRef.XPixelCenterLimits;
imagePlots(1).Y = imageRef.YPixelCenterLimits;
imagePlots(3).Y = imageRef.YPixelCenterLimits;
imagePlots(2).Y = imageRef.ZPixelCenterLimits;
imagePlots(3).X = imageRef.ZPixelCenterLimits;
[imagePlots.I] = deal(V.XYProjection, V.XZProjection, V.YZProjection); 

axisConfigs = csplot.AxisConfiguration.projViewAxes(imageRef);

fb = csmu.FigureBuilder;
fb.AxisConfigs = axisConfigs;
fb.PlotBuilders = {{imagePlots(1)}, {imagePlots(2)}, imagePlots{3}};
end