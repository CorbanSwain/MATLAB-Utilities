%FUNCTIONNAME - One-line description.
%
%   Longer, multi-line description.
%
%   Syntax:
%   -------
%   Y = FUNCTIONNAME(X) operates on `X` to return `Y`.
%
%   Inputs:
%   -------
%      X - an input
%          * type: numeric
%
%      parameter/value pairs:
%         'ParamName' - a parameter
%
%   Outputs:
%   --------
%      Y - the output
%
%   Notes:
%   ------
%   - This function has special powers.
%
%   Example 1:
%   ----------
%   A cool example.
%  
%      x = magic(5);
%      y = functionName(x);
%
%   See also OTHERFUNCTIONNAME.

% AuthorFirst AuthorLast, Year

function X = fracAssign(X, subs, value)
%% Evaluation
fracPoint = [subs{:}];
subsFloor = csmu.cellmap(@floor, subs);
subsCeil = csmu.cellmap(@ceil, subs);

indexPoints = [subsFloor{:}; subsCeil{:}];

nDim = length(subs);
spaceSize = zeros(1, nDim);

equivMask = indexPoints(1, :) == indexPoints(2, :);
spaceSize(equivMask) = 1;
spaceSize(~equivMask) = 2;

nLocs = prod(spaceSize, 'all');

tempIndexSub = cell(1, nDim);

XSize = size(X);

outsideBoundsCount = 0;

for iLoc = 1:nLocs
   samplePoint = zeros(1, nDim);
   [tempIndexSub{:}] = ind2sub(spaceSize, iLoc);
   for iDim = 1:nDim
      samplePoint(iDim) = indexPoints(tempIndexSub{iDim}, iDim);
   end
   
   if all(samplePoint >= 1) && all(samplePoint <= XSize)      
      cornerFactor = ((cell2mat(tempIndexSub) == 1) * 2) - 1;
      
      sampleWeight = prod(1 + ((samplePoint - fracPoint) .* cornerFactor));      
      samplePoint = num2cell(samplePoint);
      
      X(samplePoint{:}) = value * sampleWeight;
   else
      outsideBoundsCount = outsideBoundsCount + 1;
   end
end

if outsideBoundsCount
   %% Meta Setup
   %%% Function Metadata
   fcnName = strcat('csmu.', mfilename);
   
   %%% Logging
   L = csmu.Logger(fcnName);
   
   infoTxt = sprintf('fracPoint = [%s], size(X) = [%s]', ...
      num2str(fracPoint), ...
      num2str(XSize));
   
   if outsideBoundsCount == nLocs
      L.warn(strcat('Subscripting point was completely outside of the', ...
      ' array, no changes made to `X`; consider filtering as to not call', ...
      ' this function. %s'), infoTxt);
   else
      L.warn('Subscripting point was partially outside the array. %s', ...
         infoTxt);
   end
end
end