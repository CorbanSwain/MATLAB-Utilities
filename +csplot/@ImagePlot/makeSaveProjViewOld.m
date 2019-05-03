function fb = makeSaveProjViewOld(V, varargin)
ip = inputParser;
ip.addParameter('Name', 'untitled_projection_view');
ip.addParameter('SaveDirectory', '');
ip.addParameter('Text', '');
ip.addParameter('ScaleBar', []);
ip.addParameter('Colormap', 'inferno');
ip.addParameter('ProjectionViewArgs', {});
ip.addParameter('DoScaled', true);
ip.addParameter('CLims', []);
ip.addParameter('DoClose', false);
ip.parse(varargin{:});
name = ip.Results.Name;
figureDir = ip.Results.SaveDirectory;
txt = ip.Results.Text;
scaleBarSpec = ip.Results.ScaleBar;  % TODO
projViewArgs = ip.Results.ProjectionViewArgs;
cmap = ip.Results.Colormap;
doScaled = ip.Results.DoScaled;
cLims = ip.Results.CLims;
doClose = ip.Results.DoClose;

Isz = csmu.projectionView(V, projViewArgs{:}, 'SizeOnly', true);
I = zeros(Isz);

tb = csplot.TextPlot;
tb.X = Isz(2) - size(V, 3) / 2;
tb.Y = Isz(1) - size(V, 3) / 2;
tb.Text = txt;
tb.FontName = 'Input';
tb.FontSize = 10;
tb.Interpreter = 'none';
tb.VerticalAlignment = 'middle';
tb.HorizontalAlignment = 'center';

ac = csplot.AxisConfiguration;
gs = csplot.GridSpec;
ac.Position = gs(1, 1);
ac.YDir = 'reverse';
ac.Visible = false;
ac.XLim = 'auto';
ac.YLim = 'auto';

imPlots = csplot.ImagePlot.projView(V, projViewArgs{:});
imPlots(1).Colormap = cmap;
imPlots(1).DoScaled = doScaled;
if doScaled && isempty(cLims)
   cLims = [min(V, [], 'all'), max(V, [], 'all')];
end
imPlots(1).ColorLimits = cLims;

fb = csplot.ImagePlot.fullImageFig(I);
fb.AxisConfigs = ac;
fb.PlotBuilders = [imPlots, tb];
fb.Name = name;
fb.figure;
if ~isempty(figureDir)
   fb.save(figureDir);
end

if doClose
   fb.close;
end