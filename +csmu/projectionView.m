function [varargout] = projectionView(I, varargin)
%% Unit Test
if nargin == 0
   unittest;
   return
end

%% Parse Inputs
%%% Check Inputs
assert(any(ndims(I) == [3, 4]), ['Input image must be a grayscale (3D) or ', ...
   'color (4D) volumetric image.']);
if ndims(I) == 4
   assert(size(I, 4) == 3, 'Input image must have exactly 3 color channels');
end
p = inputParser;
p.addParameter('FillValue', [], @(x) isnumeric(x) && isreal(x) ...
   && isscalar(x));
p.addParameter('Margin', 10, @(x)  isnumeric(x) && isreal(x) && x >= 0);
p.addParameter('ProjectionFun', @(varargin) csmu.maxProject(varargin{:}), ...
   @(x) isa(x, 'function_handle'));
p.addParameter('ColorWeight', []);
p.addParameter('SizeOnly', false);
p.parse(varargin{:});

%%% Assign Inputs
outclass = class(I);
margin = p.Results.Margin;
fillValue = p.Results.FillValue;
if isempty(fillValue)
   try
      fillValue = intmax(outclass);
   catch
      fillValue = 1;
   end
end
doSizeOnly = p.Results.SizeOnly;
colorwt = p.Results.ColorWeight;
pFun = p.Results.ProjectionFun;
if ~isempty(colorwt)
   pFun = @(I, dim) pFun(I, dim, 'ColorWeight', colorwt);
end

%% Create Projection View
sz = arrayfun(@(dim) size(I, dim), 1:4);
totalSize = [sz(1:2) + sz(3) + margin, sz(4)];
if doSizeOnly
   varargout = {totalSize};
   return;
end
alphaData = false(totalSize(1:2));
Iout = ones(totalSize, outclass) * fillValue;

bounds = cell(1, 3);
bounds{1} = [1, 1; sz(1), sz(2)];
start = [sz(1) + margin + 1, 1];
bounds{2} = [start; start + [sz(3), sz(2)] - 1];
start = [1, sz(2) + margin + 1];
bounds{3} = [start; start + [sz(1), sz(3)] - 1];

projOrder = [3 1 2]; % XY, XZ, YZ
sels = cell(1, 3);
for i = 1:length(bounds)
   b = bounds{i};
   sel = {b(1, 1):b(2, 1), b(1, 2):b(2, 2), 1:totalSize(3)}; 
   view = pFun(I, projOrder(i));
   if i == 2
      view = permute(view, [2, 1, 3]);
   end
   alphaData(sel{1:2}) = true;
   sels{i} = sel;
   Iout(sel{:}) = view;
end

% convert to true bounds in world coordinates
bounds = cellfun(@(b) [b(1, :) - 0.5; b(2, :) + 0.5], ...
   bounds, 'UniformOutput', false);

switch nargout
   case 1
      varargout = {Iout};
   otherwise
      varargout = {Iout, bounds, sels, alphaData};
end
end

function unittest
L = csmu.Logger('csmu.projectionView>unittest');
L.info('mri volume image test ...');
mri = load('mri');
V = im2double(squeeze(mri.D));
V = V(1:floor(end / 2), :, :);

[I, bounds, sel, ad] = csmu.projectionView(V);

fb = csmu.FigureBuilder;
fb.Number = 1;
fb.Position = [100 91 1124 527];

pvPlots = csmu.ImagePlot.projView(V);
diagPlots = cell(1, 3);
for i = 1:3
   lp = csmu.LinePlot;
   lp.X = bounds{i}(:, 2);
   lp.Y = bounds{i}(:, 1);
   lp.LineSpec = {'r+-'};
   lp.LineWidth = {1};
   lp.MarkerSize = {10};
   diagPlots{i} = lp;
end

axConfig = csmu.AxisConfiguration;
axConfig.YDir = 'reverse';
axConfig.Visible = 'off';
axConfig.PBAspect = [1 1 1];

fb.AxisConfigs = {axConfig};
fb.PlotBuilders = {[pvPlots, diagPlots]};
fb.figure;


figure(2); clf; hold on;
h = imagesc(I, 'AlphaData', ad);
for i = 1:3
   plot(flip(bounds{i}(:, 2)), bounds{i}(:, 1), ...
      'r+-', 'LineWidth', 1, 'MarkerSize', 10);
end
ax = gca;
ax.YDir = 'reverse';
h.CData(sel{1}{:}) = 0;
h.CData(sel{2}{:}) = 1;
h.CData(sel{3}{:}) = 1;
colorbar(ax);
L.info('\tpassed.');

L.info('uint8 color image Test ...');
V = csmu.double2im(csmu.fullscaleim(cat(4, V * 1, V * 0, V * 1)), 'uint8');
[I, bounds, sel, ad] = csmu.projectionView(V);
figure(3); clf; hold on;
imagesc(I, 'AlphaData', ad);
for i = 1:3
   plot(bounds{i}(:, 2), bounds{i}(:, 1), ...
      'r+-', 'LineWidth', 1, 'MarkerSize', 10);
end
ax = gca;
ax.YDir = 'reverse';
L.info('\tpassed.')
end
