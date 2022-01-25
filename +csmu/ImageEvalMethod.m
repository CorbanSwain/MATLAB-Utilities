%IMAGEEVALMETHOD - Class Title
%
%   Longer enumeration class description. 
%
%   derives from: superclassname1, superclassname2
%
%   enumeration members:
%   --------------------
%      Member1 ('a')
%      Member2 ('b')
%
%   enumclassname properties:
%   -------------------------
%      Prop1 - short prop description (longer description in properties
%              block).
%
%   enumclassname methods:
%   ----------------------
%      method1 - short method description (longer descriptions within each
%                method definition.)
%
%   Example 1:
%   ----------
%   % A class example.
%   m = enumclassname.Member1;
%
%   See also OTHERCLASS.

classdef ImageEvalMethod
   enumeration
      RelativeSumTruthy
      RelativeSumFalsy
      RelativeCountTruthy
      RelativeCountFalsy
      SumTruthyRateCurve
      CountTruthyRateCurve
      FakeSNR
      PSNR
      Correlation
      DBSNR      
      Resolution
      MinVal
      MaxVal
      FractionNonZero
      FractionFinite
      Histogram
      LogHistogram
   end

   properties (Dependent)
      RequiresReferenceImage
   end

   methods 

      function result = evaluate(self, I, varargin)
         %% Meta Setup
         %%% Function Metadata
         fcnName = strcat('analysis.', mfilename, '.evaluate');

         %%% Logging
         L = csmu.Logger(fcnName);

         %%% Input Handling
         ip = csmu.InputParser.fromSpec({
            {'p', 'NumHistBins', 64, @csmu.validators.integerValue}
            });
         ip.DoKeepUnmatched = true;
         ip.FunctionName = fcnName;
         ip.parse(varargin{:});
         inputs = ip.Results;

         if self.RequiresReferenceImage
            result = self.evaluateWithRef(I, varargin{:});
            return
         end        

         switch self
            case 'Resolution'
               result = struct();
               [result.Median, result.Data] = self.evalResolution(I, inputs);

            case 'MinVal'
               result = min(I, [], 'all');

            case 'MaxVal'
               result = max(I, [], 'all');

            case 'FractionNonZero'
               result = sum(I > 0, 'all') / numel(I);

            case 'FractionFinite'
               result = sum(isfinite(I), 'all') / numel(I);

            case 'Histogram'               
               [counts, binLocs] = imhist(I, inputs.NumHistBins);
               binEdges = csmu.imhistLocs2Edges(binLocs);
               
               result = struct();
               result.BinCounts = counts;
               result.BinEdges = binEdges;

            case 'LogHistogram'
               IRescaled = csmu.fullscaleim(I);
               [IRemaped, minClip, maxClip] = csmu.logremap(IRescaled);
               [counts, binLocs] = imhist(IRemaped, inputs.NumHistBins);
               binEdges = csmu.imhistLocs2Edges(binLocs);
               binEdgesUnmaped = csmu.logremap(binEdges, minClip, maxClip, ...
                  DoInvert=true);
               
               result = struct();
               result.BinCounts = counts;
               result.BinEdges = binEdgesUnmaped;
               result.BinEdgesRaw = binEdges;

            otherwise
               L.error('Unexpected ImageEvalMethod passed, %s.', ...
                  self)
         end
         
      end

      function result = evaluateWithRef(self, I, varargin)
         %% Meta Setup
         %%% Function Metadata
         fcnName = strcat('analysis.', mfilename, '.evaluateWithRef');

         %%% Logging
         % L = csmu.Logger(fcnName);

         %%% Input Handling
         ip = csmu.InputParser.fromSpec({
            {'rp', 'ReferenceImage'}
            {'p', 'NumCurvePoints', 16}
            });
         ip.DoKeepUnmatched = true;
         ip.FunctionName = fcnName;
         ip.parse(varargin{:});
         inputs = ip.Results;

         R = inputs.ReferenceImage;

         repassedInputs = inputs;
         repassedInputs = rmfield(repassedInputs, 'ReferenceImage');

         try
            clsmax = double(intmax(class(I)));
            L.assert(strcmp(class(I), class(R)), ...
               ['If int type, image and reference must be of the same int ' ...
               'type.']);
         catch
            clsmax = 1;
         end

         switch self
            case 'RelativeSumTruthy'
               repassedInputs.Method = 'values';
               repassedInputs.DoSumTrue = true;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'RelativeSumFalsy'
               repassedInputs.Method = 'values';
               repassedInputs.DoSumTrue = false;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'RelativeCountTruthy'
               repassedInputs.Method = 'counts';
               repassedInputs.DoSumTrue = true;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'RelativeCountFalsy'
               repassedInputs.Method = 'counts';
               repassedInputs.DoSumTrue = false;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'SumTruthyRateCurve'
               repassedInputs.Method = 'values';
               repassedInputs.DoSumTrue = true;
              
               samplePoints = linspace(0, 1, inputs.NumCurvePoints);
               sumPoints = zeros(1, inputs.NumCurvePoints);
               for iPoint = 1:inputs.NumCurvePoints
                  repassedInputs.FractionCutoff = samplePoints(iPoint);
                  sumPoints(iPoint) = ...
                     self.binaryEvalHelper(I, R, repassedInputs);
               end
               result.ExpectedRatio = samplePoints;
               result.ObservedRatio = sumPoints;

            case 'CountTruthyRateCurve'
               repassedInputs.Method = 'counts';
               repassedInputs.DoSumTrue = true;

               samplePoints = linspace(0, 1, inputs.NumCurvePoints);
               sumPoints = zeros(1, inputs.NumCurvePoints);
               for iPoint = 1:inputs.NumCurvePoints
                  repassedInputs.FractionCutoff = samplePoints(iPoint);
                  sumPoints(iPoint) = ...
                     self.binaryEvalHelper(I, R, repassedInputs);
               end
               result.ExpectedRatio = samplePoints;
               result.ObservedRatio = sumPoints;

            case 'SumOutside'
               rawVal = self.evalSumOutside(I, R, repassedInputs);
               result = rawVal / clsmax;

            case 'FakeSNR'
               insideSelect = boolean(R);
               signal = sum(I(insideSelect), 'all') ./ numel(R);
               noise = sum(I(~insideSelect), 'all') ./ numel(R);
               result = 20 * log10(signal / noise);

            case 'PSNR'
               if ~isfloat(I), I = double(I); end
               if ~isfloat(R), R = double(R); end
               rmse = @(x, y) sqrt(mean((x(:) - y(:)) .^ 2));
               result = 20 * log10(clsmax / rmse(I, R));

            case 'Correlation'
               if ~isfloat(I), I = double(I); end
               if ~isfloat(R), R = double(R); end
               corrmat = corrcoef(I(:), R(:));
               result = corrmat(1, 2);

            case 'DBSNR'
               if ~isfloat(I), I = double(I); end
               if ~isfloat(R), R = double(R); end
               result = 20 * log10(sumsqr(R) / sumsqr(R - I));

            otherwise
               L.error('Unexpected ImageEvalMethod passed, %s.', ...
                  self)
         end

      end

      %% Get/Set Methods
      function out = get.RequiresReferenceImage(self)
         switch self
            case {'RelativeSumTruthy', ...
                  'RelativeSumFalsy', ...
                  'RelativeCountTruthy', ...
                  'RelativeCountFalsy', ...
                  'SumTruthyRateCurve', ...
                  'CountTruthyRateCurve', ...
                  'FakeSNR', ...
                  'PSNR', ...
                  'Correlation', ...
                  'DBSNR'}
               out = true;
            otherwise
               out = false;
         end
      end

   end

   methods (Static)
      function output = runAllMethods(I, varargin)
         [methods, methodNames] = enumeration('csmu.ImageEvalMethod');

         output = struct();
         for iMethod = 1:length(methods)
            method = methods(iMethod);
            methodName = methodNames{iMethod};
            methodOutputStruct = struct();
            methodOutputStruct.Method = method;
            try
               fprintf('Attempting method %s\n', methodName)
               result = method.evaluate(I, varargin{:});
               methodOutputStruct.Result = result;
               methodOutputStruct.DidFail = false;
            catch ME
               methodOutputStruct.DidFail = true;
               methodOutputStruct.errorId = ME.identifier;
               methodOutputStruct.errorMsg = ME.message;
            end

            output.(methodName) = methodOutputStruct;
         end
      end

      function result = binaryEvalHelper(I, R, varargin)
         fcnName = strcat('csmu.', mfilename, '.evalSumOutside');

         % L = csmu.Logger(fcnName);

         ip = csmu.InputParser.fromSpec({
            {'rp', 'Method', {'values', 'counts'}}           

            {'p', 'PrctCutoff', []}
            {'p', 'FractionCutoff', []}
            {'p', 'DoSumTrue', true}           
            });         
         ip.FunctionName = fcnName;
         ip.DoKeepUnmatched = true;
         ip.parse(varargin{:});
         inputs = ip.Results;

         if ~isempty(inputs.FractionCutoff)
            prctCutoff = inputs.FractionCutoff * 100;
         elseif ~isempty(inputs.PrctCutoff)
            prctCutoff = inputs.PrctCutoff;
         else
            prctCutoff = 50;
         end

         if inputs.PrctCutoff == 0
            mask = boolean(R);
            prctileVal = 0.5;
         else
            prctileVal = prctile(R, prctCutoff, 'all');
            mask = R >= prctileVal;            
         end

         if ~inputs.DoSumTrue
            mask = ~mask;
         end

         switch inputs.Method
            case 'values'
               % refSumFrac = sum(R(mask), 'all') / sum(R, 'all');
               sumFrac = sum(I(mask), 'all') / sum(I, 'all');

            case 'counts'
               % refSumFrac = sum(mask, 'all') / numel(R);
               if inputs.DoSumTrue
                  sumFrac = sum(I >= prctileVal, 'all') / numel(I);
               else
                  sumFrac = sum(I < prctileVal, 'all') / numel(I);
               end
         end
         result = sumFrac;
      end

      function [varargout] = evalResolution(I, varargin)
         fcnName = strcat('csmu.', mfilename, '.evalResolution');

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
               L.debug(['Attempting to measure resolution at location %02d ' ...
                  '/ %02d.'], ...
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

            invalidPeakPosCriterion = ...
               any(rm.PeakPosition <= (inputs.BeadValidityEdgeMargin)) ...
               || any(rm.PeakPosition ...
               >= (size(I) - inputs.BeadValidityEdgeMargin + 1));
            if invalidPeakPosCriterion
               continue
            end

            rawValues = [rawValues; rm.PeakWidth];
         end

         L.debug(['%d of %d resolution measurements made in this ' ...
            'volumetric image.'], ...
            size(rawValues, 1), nLocations);

         if isempty(rawValues)
            medianRes = [NaN, NaN, NaN];
         else
            medianRes = median(rawValues, 1);
         end

         switch nargout
            case {0, 1}
               varargout = {medianRes};
            
            otherwise
               varargout = {medianRes, rawValues};
         end
      end

   end
end