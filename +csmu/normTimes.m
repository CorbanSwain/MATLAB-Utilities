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

function y = normTimes(x1, x2)

%% Meta Setup
%%% Input Handling
narginchk(2, 2);

%% Computation
outputRange = csmu.range([csmu.range(x1, 'all'), csmu.range(x2, 'all')], 'all');
outputRangeSize = diff(outputRange);

y = times(x1, x2);

tempRange = csmu.range(y, 'all');
tempRangeSize = diff(tempRange);

y = ((y - tempRange(1)) * (outputRangeSize / tempRangeSize)) + outputRange(1);
end