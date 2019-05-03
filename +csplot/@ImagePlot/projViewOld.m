function plots = projViewOld(varargin)
imPlot = csplot.ImagePlot;
[I, bounds, ~, ad] = csmu.projectionView(varargin{:});
imPlot.I = I;
imPlot.AlphaData = ad;
imPlot.Colormap = 'gray';

labelPlots = csmu.addProjViewLabels(bounds, 'Color', 'w');
plots = [imPlot, labelPlots];
end