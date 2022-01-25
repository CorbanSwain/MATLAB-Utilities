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

function schedule = freq2schedule(frequency, schdLength)

%% Input Handling
arguments
   frequency (1, 1) {mustBeInRange(frequency, 0, 1)}
   schdLength (1, 1) {mustBeInteger}
end

%% Evaluation
if frequency == 1
   schedule = true(1, schdLength);
elseif frequency == 0
   schedule = false(1, schdLength);
else
   numTrue = round(frequency * schdLength);
   numFalse = schdLength - numTrue;

   ratio = numTrue / numFalse;
   if ratio <= 1
      ratio = 1 / ratio;
      doInvert = true;
   else
      doInvert = false;
   end

   intRatio = round(ratio);
   if isfinite(intRatio)
      unitCell = [true(1, intRatio), false(1, 1)];
   else
      unitCell = true(1, 1);
   end
   numRepeats = ceil(schdLength / length(unitCell));

   schedule = repmat(unitCell, 1, numRepeats);
   schedule = schedule(1:schdLength);

   if doInvert
      schedule = not(schedule);
   end
end

end