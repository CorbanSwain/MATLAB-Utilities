function score = scoreim(I, varargin)
L = csmu.Logger('csmu.scoreim');

% FIXED - this only works with boolean reference images right now.
persistent R;
if nargin == 1
   L.info('Saving reference image in persistent store.')
   R = I;
   return;
end

p = inputParser;
methodList = {'sumOutside', 'fakeSnr', 'psnr', 'correlation', 'all', ...
   'dbsnr', 'resolution'};
p.addParameter('method', 'all', @(x) any(strcmp(x, methodList)));
p.addParameter('ScoreFcnArgs', {});
p.parse(varargin{:});
inputs = p.Results;
method = inputs.method;


L.assert(all(size(I) == size(R)), ['Image and reference image must have', ...
   ' the same size.']);

try
   clsmax = double(intmax(class(I)));
   L.assert(strcmp(class(I), class(R)), ...
      'If int type, image and reference must be of the same int type.');
catch
   clsmax = 1;
end

doAll = strcmpi(method, 'all');
nMeth = length(methodList) - 1;
score = [];

for iMeth = 1:nMeth
   if doAll
      method = methodList{iMeth};
   end
   switch method
      case 'sumOutside'
         rawVal = evalSumOutside(R, I, inputs.ScoreFcnArgs{:});
         score = [score, (rawVal / clsmax * 100)];
         
      case 'fakeSnr'
         insideSelect = boolean(R);
         signal = sum(I(insideSelect), 'all') ./ numel(R);
         noise = sum(I(~insideSelect), 'all') ./ numel(R);
         score = [score, (20 * log10(signal / noise))];
         
      case 'psnr'
         if ~isfloat(I), I = double(I); end
         if ~isfloat(R), R = double(R); end
         rmse = @(x, y) sqrt(mean((x(:) - y(:)) .^ 2));
         score = [score, (20 * log10(clsmax / rmse(I, R)))];
         
      case 'correlation'
         if ~isfloat(I), I = double(I); end
         if ~isfloat(R), R = double(R); end
         corrmat = corrcoef(I(:), R(:));
         score = [score, corrmat(1, 2)];
         
      case 'dbsnr'
         if ~isfloat(I), I = double(I); end
         if ~isfloat(R), R = double(R); end
         score = [score, 20 * log10(sumsqr(R) / sumsqr(R - I))];
         
      case 'resolution'
         result = evalResolution(I, inputs.ScoreFcnArgs{:});
         if doAll
            score = [score, result(end)]; % only append z resolution if
            %                             % doing all reconstruction
            %                             % methods
         else
            score = result;
         end
         
      otherwise
         L.error('Unrecognized method: ''%s''', method);
   end
   
   if ~isreal(score(end))
      L.warn('Score for "%s" has imaginary component, removing.', method);
      score(end) = real(score(end));
   end
   
   if ~doAll
      return
   end
end
end

function sumOutside = evalSumOutside(R, I, varargin)
fcnName = strcat('csmu.', mfilename, '/evalResolution');

L = csmu.Logger(fcnName);

ip = csmu.InputParser.fromSpec({
   {'p', 'PrctCutoff', 0}
   });
ip.FunctionName = fcnName;
ip.DoKeepUnmatched = true;
ip.parse(varargin{:});
inputs = ip.Results;

if inputs.PrctCutoff == 0
   outsideMask = ~boolean(R);
else
   outsideMask = R <= prctile(R, inputs.PrctCutoff, 'all');
end

sumOutside = sum(I(outsideMask), 'all') / numel(R);
end


function medianRes = evalResolution(I, varargin)
fcnName = strcat('csmu.', mfilename, '/evalResolution');

L = csmu.Logger(fcnName);

ip = csmu.InputParser.fromSpec({
   {'rp', 'BeadLocations'}
   {'p', 'ResMeasureCalculateArgs', false}
   {'p', 'DoMakeResMeasureFigures', false}
   {'p', 'BeadValidityEdgeMargin', 0}
   });
ip.FunctionName = fcnName;
ip.DoKeepUnmatched = true;
ip.parse(varargin{:});
inputs = ip.Results;

if isequal(inputs.ResMeasureCalculateArgs, false)
   calcArgs = {
      'DoRefinePointBy3DCentroid', true, ...
      'CentroidSearchRadius', 5, ...
      'DoRefinePointBy1DPeaks', true, ...
      'Maximum1DPeakDistance', 8, ...
      'PeakLocationReference', 'maximum', ...
      'FindpeaksArgs', {'MinPeakHeight', 0.01}, ...
      'MaximumPeakWidth', inf};
else
   calcArgs = inputs.ResMeasureCalculateArgs;
end

resMeasureFigureArgs = {
   'DoDarkMode', true, ...
   'FontName', 'Helvetica LT Pro', ...
   'DoShowSampleAxis', true, ...
   'DoShowAxisLabels', true, ...
   'DoShowPeakMarker', false, ...
   'DoShowMeasurementText', false, ...
   'ViewWidth', 80, ...
   'PlotLayout', 1};

nLocations = size(inputs.BeadLocations, 1);

if nLocations == 0
   medianRes = [NaN, NaN, NaN];
   return
end

resMeasures(1, nLocations) = csmu.ResolutionMeasurement();

for iBead = 1:nLocations   
   try
      L.debug('Attempting to measure resolution at location %02d / %02d.', ...
         iBead, nLocations);
      resMeasures(iBead) = csmu.ResolutionMeasurement.calculate(...
         I, ...
         inputs.BeadLocations(iBead, :), ...
         calcArgs{:});
      
      if inputs.DoMakeResMeasureFigures
         fb = resMeasures(iBead).prettyFigure(resMeasureFigureArgs{:});
         fb.figure();
      end
   catch ME
      L.debug(strcat('Error raised while attempting to calculate', ...
         ' resolution at a bead location (# %d).'), iBead);
      L.logException(csmu.LogLevel.TRACE, ME);
   end
end

rawValues = zeros(0, 3);
for iBead = 1:nLocations
   rm = resMeasures(iBead);
   if ~all(rm.PeakValid)
      continue
   end
   
   if any(rm.PeakPosition <= inputs.BeadValidityEdgeMargin)
      continue
   end
   
   if any(rm.PeakPosition >= (size(I) - inputs.BeadValidityEdgeMargin + 1))
      continue
   end   
   
   rawValues = [rawValues; rm.PeakWidth];
end

L.debug('%d of %d resolution measurements made in this volumetric image.', ...
   size(rawValues, 1), nLocations);

if isempty(rawValues)
   medianRes = [NaN, NaN, NaN];
else   
   medianRes = median(rawValues, 1);
end
end
