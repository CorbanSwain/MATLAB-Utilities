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
      RelativeSumTruthy ...
         (true, 'double', 'Relative Sum Dark', 'a.u.', ...
         NaN)
      RelativeSumFalsy ...
         (true, 'double', 'Relative Sum Light', 'a.u.', ...
         NaN)
      RelativeCountTruthy ...
         (true, 'double', 'Relative Count Dark', 'a.u.', ...
         NaN)
      RelativeCountFalsy ...
         (true, 'double', 'Relative Count Light', 'a.u.', ...
         NaN)
      FracMatchTruthy ...
         (true, 'double', 'Matched, Light Cutoff', 'fraction', ...
         NaN)
      FracMatchFalsy ...
         (true, 'double', 'Matched, Dark Cutoff', 'fraction', ...
         NaN)
      CountRateCurve ...
         (true, 'struct', 'Observed Dark vs. Expected Dark', 'fraction', ...
         struct(FracDark=[], ObservedDark=[], AbsABC=NaN))
      MatchRateCurve ...
         (true, 'struct', 'Binary Matched vs. Expected Dark', 'fraction', ...
         struct(FracDark=[], FracMatched =[], AUC=NaN))
      FakeSNR ...
         (true, 'double', 'Sum Truthy / Sum Falsy', 'dB', ...
         NaN)
      PSNR ...
         (true, 'double', 'Peak Signal-to-Noise Ratio', 'dB', ...
         NaN)
      Correlation ...
         (true, 'struct', 'Correlation', 'a.u.', ...
         struct(Correlation=NaN, CorrMat=[]))
      DBSNR ...
         (true, 'double', 'Signal-to-Noise Ratio', 'dB', ...
         NaN)
      Resolution ...
         (false, 'struct', 'Resolution', 'voxels', ...
         struct(Median=NaN, Data=[]))
      MinVal ...
         (false, 'double', 'Minimum Value', 'i.u.', ...
         NaN)
      MaxVal ...
         (false, 'double', 'Maximum Value', 'i.u.', ...
         NaN)
      FractionNonZero ...
         (false, 'double', 'Non Zero Voxels', 'fraction', ...
         NaN)
      FractionFinite ...
         (false, 'double', 'Finite Voxels', 'fraction', ...
         NaN)
      Histogram ...
         (false, 'struct', 'Intensity Histogram', 'counts', ...
         struct(BinCounts=[], BinEdges=[], BinLocs=[]))
      LogHistogram ...
         (false, 'struct', 'Log Limits Intensity Histogram', 'counts', ...
         struct(BinCounts=[], BinEdges=[], BinLocs=[], BinEdgesLog=[], ...
         BinLocsLog=[]))
   end

   properties
      RequiresReferenceImage
      DataType
      FullName
      PrimaryUnits
      InitResultValue
   end

   properties (Dependent)
      Name
   end

   methods 

      function self = ImageEvalMethod(...
            doesRequireRef, resultDataType, fullName, units, initValue)
         self.RequiresReferenceImage = doesRequireRef;
         self.DataType = resultDataType;
         self.FullName = fullName;
         self.PrimaryUnits = units;
         self.InitResultValue = initValue;         
      end

      function result = evaluate(self, I, varargin)
         %% Meta Setup
         %%% Function Metadata
         fcnName = strcat('analysis.', mfilename, '.evaluate');

         %%% Logging
         L = csmu.Logger(fcnName);

         %%% Input Handling
         ip = csmu.InputParser.fromSpec({
            {'p', 'NumHistBins', 64, @csmu.validators.integerValue}
            {'p', 'ImUnscaled', []}
            });
         ip.DoKeepUnmatched = true;
         ip.FunctionName = fcnName;
         ip.parse(varargin{:});
         inputs = ip.Results;

         if self.RequiresReferenceImage
            result = self.evaluateWithRef(I, varargin{:});
         else
            IUnscaled = inputs.ImUnscaled;
            if isempty(IUnscaled)
               IUnscaled = I;
            end

            switch self
               case 'Resolution'
                  IRescaled = csmu.fullscaleim(I);

                  result = struct();
                  [result.Median, result.Data] = ...
                     self.evalResolution(IRescaled, inputs);

               case 'MinVal'
                  result = min(IUnscaled, [], 'all');

               case 'MaxVal'
                  result = max(IUnscaled, [], 'all');

               case 'FractionNonZero'
                  result = sum(IUnscaled > 0, 'all') / numel(I);

               case 'FractionFinite'
                  result = sum(isfinite(I), 'all') / numel(I);

               case 'Histogram'
                  [counts, binLocs] = imhist(IUnscaled, inputs.NumHistBins);
                  binEdges = csmu.imhistLocs2Edges(binLocs);

                  result = struct();
                  result.BinCounts = counts;
                  result.BinEdges = binEdges;
                  result.BinLocs = binLocs;

               case 'LogHistogram'
                  IRescaled = csmu.fullscaleim(I);

                  [IRemaped, minClip, maxClip] = csmu.logremap(IRescaled);
                  [counts, binLocs] = imhist(IRemaped, inputs.NumHistBins);
                  binEdges = csmu.imhistLocs2Edges(binLocs);
                  binLocsUnmaped = csmu.logremap(binLocs, minClip, maxClip, ...
                     DoInvert=true);
                  binEdgesUnmaped = csmu.logremap(binEdges, minClip, ...
                     maxClip, DoInvert=true);

                  result = struct();
                  result.BinCounts = counts;
                  result.BinEdges = binEdgesUnmaped;
                  result.BinLocs = binLocsUnmaped;
                  result.BinEdgesLog = binEdges;
                  result.BinLocsLog = binLocs;

               otherwise
                  L.error('Unexpected ImageEvalMethod passed, %s.', ...
                     self)
            end
         end
         

         L.assert(isa(result, self.DataType), ...
            'Result is of class ''%s'', expected ''%s''.', ...
            class(result), self.DataType);

         switch self.DataType
            case 'struct'
               L.assert(csmu.doFieldsMatch(result, self.InitResultValue), ...
                  ['Unexpected mismatch between result struct and expected ' ...
                  'struct.']);

            case 'double'
               L.assert(isscalar(result), ...
                  'Expected result output to be a scalar double.');
         end
      end

      function result = evaluateWithRef(self, I, varargin)
         %% Meta Setup
         %%% Function Metadata
         fcnName = strcat('analysis.', mfilename, '.evaluateWithRef');

         %%% Logging
         L = csmu.Logger(fcnName);

         %%% Input Handling
         ip = csmu.InputParser.fromSpec({
            {'rp', 'ReferenceImage'}
            {'p', 'NumCurvePoints', 16}
            {'p', 'PrctCutoff', []}
            {'p', 'FractionCutoff', []}
            });
         ip.DoKeepUnmatched = true;
         ip.FunctionName = fcnName;
         ip.parse(varargin{:});
         inputs = ip.Results;

         R = inputs.ReferenceImage;

         repassedInputs = inputs;
         repassedInputs = rmfield(repassedInputs, 'ReferenceImage');


         L.assert(strcmp(class(I), class(R)), ...
            ['If int type, image and reference must be of the same int ' ...
            'type.']);


         switch self
            case 'RelativeSumTruthy'
               repassedInputs.Method = 'values';
               repassedInputs.DoSumTrue = true;
               repassedInputs.DoRelative = true;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'RelativeSumFalsy'
               repassedInputs.Method = 'values';
               repassedInputs.DoSumTrue = false;
               repassedInputs.DoRelative = true;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'RelativeCountTruthy'
               repassedInputs.Method = 'counts';
               repassedInputs.DoSumTrue = true;
               repassedInputs.DoRelative = true;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'RelativeCountFalsy'
               repassedInputs.Method = 'counts';
               repassedInputs.DoSumTrue = false;
               repassedInputs.DoRelative = true;
               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'FracMatchTruthy'
               repassedInputs.Method = 'match';
               repassedInputs.DoSumTrue = true;

               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'FracMatchFalsy'
               repassedInputs.Method = 'match';
               repassedInputs.DoSumTrue = false;

               result = self.binaryEvalHelper(I, R, repassedInputs);

            case 'CountRateCurve'
               repassedInputs.Method = 'counts';
               repassedInputs.DoSumTrue = false;

               samplePoints = linspace(0, 1, inputs.NumCurvePoints);
               repassedInputs.FractionCutoff = samplePoints;

               countPoints = self.binaryEvalHelper(I, R, repassedInputs);

               result.FracDark = samplePoints;
               result.ObservedDark = countPoints;
               result.AbsABC = trapz(samplePoints, ...
                  abs(countPoints - samplePoints));

            case 'MatchRateCurve'
               repassedInputs.Method = 'match';
               repassedInputs.DoSumTrue = false;

               samplePoints = linspace(0, 1, inputs.NumCurvePoints);
               repassedInputs.FractionCutoff = samplePoints;

               matchFracCurve = self.binaryEvalHelper(I, R, repassedInputs);

               result.FracDark = samplePoints;
               result.FracMatched = matchFracCurve;
               result.AUC = trapz(samplePoints, matchFracCurve);

            case 'FakeSNR'
               if islogical(R)
                  truthySelect = R;
               else
                  if ~isempty(inputs.FractionCutoff)
                     prctCutoff = inputs.FractionCutoff * 100;
                  elseif ~isempty(inputs.PrctCutoff)
                     prctCutoff = inputs.PrctCutoff;
                  else
                     prctCutoff = 50;
                  end

                  prctileVal = self.cachedPrctile(R, prctCutoff, 'all');

                  minR = min(R, [], 'all');
                  if prctileVal <= minR
                     truthySelect = true(size(R));
                  else
                     truthySelect = R > prctileVal;
                  end
               end                              

               signal = sum(I(truthySelect), 'all');
               noise = sum(I(~truthySelect), 'all');
               result = 20 * log10(signal / noise);

            case 'PSNR'
               if ~isfloat(I), I = double(I); end
               if ~isfloat(R), R = double(R); end
               maxR = max(R, [], 'all');
               rmse = @(x, y) sqrt(mean((x(:) - y(:)) .^ 2));
               result = 20 * log10(maxR/ rmse(I, R));

            case 'Correlation'
               if ~isfloat(I), I = double(I); end
               if ~isfloat(R), R = double(R); end
               corrmat = corrcoef(I(:), R(:));
               result.Correlation = corrmat(1, 2);
               result.CorrMat = corrmat;

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
      function out = get.Name(self)
         out = char(string(self));
      end

   end

   methods (Static)
      function output = runAllMethods(I, varargin)
         methods = enumeration('csmu.ImageEvalMethod');
         output = csmu.ImageEvalMethod.runMethods(methods, I, varargin{:});
      end

      function output = runMethods(methods, I, varargin)
         fcnName = strcat('csmu.', mfilename, '.runMethods');
         L = csmu.Logger(fcnName);

         ip = csmu.InputParser.fromSpec({ ...
            {'p', 'DoFailOnError', false, 'logicalScalar'}
            });
         ip.FunctionName = fcnName;
         ip.DoKeepUnmatched = true;
         ip.parse(varargin{:});
         inputs = ip.Results;

         L.debug('Beginning series of image evaluations.');

         output = struct();
         for iMethod = 1:length(methods)            
            method = csmu.ImageEvalMethod(methods(iMethod));

            L.debug('Evaluating image with method: "%s"', method.Name);

            methodOutputStruct = struct();
            methodOutputStruct.Method = method;
            try
               result = method.evaluate(I, varargin{:});
               methodOutputStruct.Result = result;
               methodOutputStruct.DidFail = false;
               L.debug('Image evaluation succeded.')
            catch ME
               methodOutputStruct.DidFail = true;
               methodOutputStruct.errorId = ME.identifier;
               methodOutputStruct.errorMsg = ME.message;
               
               L.debug('Image evaluation failed.')

               if inputs.DoFailOnError
                  rethrow(ME);
               end               
            end

            output.(method.Name) = methodOutputStruct;
         end
      end

      function result = binaryEvalHelper(I, R, varargin)
         fcnName = strcat('csmu.', mfilename, '.evalSumOutside');

         % L = csmu.Logger(fcnName);

         ip = csmu.InputParser.fromSpec({
            {'rp', 'Method', {'values', 'counts', 'match'}}           

            {'p', 'PrctCutoff', []}
            {'p', 'FractionCutoff', []}
            {'p', 'DoSumTrue', true}
            {'p', 'DoRelative', false}
            });         
         ip.FunctionName = fcnName;
         ip.DoKeepUnmatched = true;
         ip.parse(varargin{:});
         inputs = ip.Results;

         if ~isempty(inputs.FractionCutoff)
            prctCutoff = csmu.bound(inputs.FractionCutoff * 100, 0, 100);
         elseif ~isempty(inputs.PrctCutoff)
            prctCutoff = inputs.PrctCutoff;
         else
            prctCutoff = 50;
         end       
        
         prctileVals = csmu.ImageEvalMethod.cachedPrctile(...
            R, prctCutoff, 'all');
         numMeasures = length(prctileVals);

         useMaskCriterion = any(strcmpi(inputs.Method, {'values', 'match'})) ...
            || inputs.DoRelative;

         if useMaskCriterion
            masks = cell(1, numMeasures);
            sizeR = size(R);

            minR = min(R, [], 'all');
            maxR = max(R, [], 'all');
            for iMeasure = 1:numMeasures
               masks{iMeasure} = false(sizeR);
               prctileVal = prctileVals(iMeasure);

               if inputs.DoSumTrue
                  if (prctileVal <= minR) && (prctCutoff(iMeasure) <= 0)
                     masks{iMeasure}(:) = true;
                  else
                     masks{iMeasure} = R > prctileVal;
                  end
               else
                  if prctileVal >= maxR && (prctCutoff(iMeasure) >= 100)
                     masks{iMeasure}(:) = true;
                  else
                     masks{iMeasure} = R < prctileVal;
                  end
               end
            end
         end
       
         if any(strcmpi(inputs.Method, {'counts', 'match'}))
            numelI = numel(I);
            maxI = max(I, [], 'all');
            minI = min(I, [], 'all');

            if strcmpi(inputs.Method, 'match')
               sizeI = size(I);
            end
         end
         
         result = zeros(1, numMeasures);
         for iMeasure = 1:numMeasures
            if useMaskCriterion
               refMask = masks{iMeasure};
            end

            switch inputs.Method
               case 'values'                     
                  sumFrac = sum(I(refMask), 'all') / sum(I, 'all');

                  if inputs.DoRelative
                     refSumFrac = sum(R(refMask), 'all') / sum(R, 'all');
                     result(iMeasure) = sumFrac / refSumFrac;
                  else
                     result(iMeasure) = sumFrac;
                  end

               case 'counts'
                  prctileVal = prctileVals(iMeasure);

                  if inputs.DoSumTrue                     
                     if (prctileVal == minI) && (prctCutoff(iMeasure) <= 0)
                        countFrac = 1;
                     else
                        countFrac = sum(I > prctileVal, 'all') / numelI;
                     end
                  else
                     if (prctileVal == maxI) && (prctCutoff(iMeasure) >= 100)
                        countFrac = 1;
                     else
                        countFrac = sum(I < prctileVal, 'all') / numelI;
                     end
                  end

                  if inputs.DoRelative
                     refCountFrac = sum(refMask, 'all') / numel(R);
                     result(iMeasure) = countFrac / refCountFrac;
                  else
                     result(iMeasure) = countFrac;
                  end

               case 'match'
                  prctileVal = prctileVals(iMeasure);

                  testMask = false(sizeI);
                  if inputs.DoSumTrue                     
                     if prctileVal <= minI
                        testMask(:) = true;
                     else
                        testMask = I > prctileVal;
                     end
                  else
                     if prctileVal >= maxI
                        testMask(:) = true;
                     else
                        testMask = I < prctileVal;
                     end
                  end

                  matchedMask = ~xor(testMask, refMask);
                  fracMatched = sum(matchedMask, 'all') / numelI;
                  result(iMeasure) = fracMatched;
            end

           
         end
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
            varargout = {medianRes, []};
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

      %% Method Signatures (defined in seperate files)
      out = cachedPrctile(I, varargin)

   end

end