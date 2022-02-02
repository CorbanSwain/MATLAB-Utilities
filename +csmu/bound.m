function X = bound(X, minVal, maxVal, varName)
%BOUND Bound values in an array between a min and/or max value.
%
% BOUND(X, min, max) will reduce all items in X greater than max to max,
% and less than min to min. X can be a scalar, vector, or matrix. min and
% max can either be scalar or have the same shape as X.
%
% BOUND(X, min, max, name) behaves as BOUND(X, min, max) but will also
% display a warning message if truncating of values is necessary. name is a
% char array or string used in the warning message.
%
% by Corban Swain, 2017
if nargin == 0
   unittest;
   return
end


switch nargin
   case 3
      doWarn = false;
   case 4
      doWarn = true;
   otherwise
      error('Unexpected number of arguments.');
end

doCheckMin = ~isempty(minVal);
doCheckMax = ~isempty(maxVal);

if doCheckMin
   lessThanMin = X < minVal;
end

if doCheckMax
   greaterThanMax = X > maxVal;
end

if doWarn
   if doCheckMin && any(lessThanMin, 'all')
      warning('%s cannot be smaller than [%s], truncating value(s).', ...
         varName, num2str(minVal));
   end
   if doCheckMax && any(greaterThanMax, 'all')
      warning('%s cannot be larger than [%s], truncating value(s).', ...
         varName, num2str(maxVal));
   end
end

if doCheckMin
   if isscalar(minVal)
      X(lessThanMin) = minVal;
   else
      X(lessThanMin) = minVal(lessThanMin);
   end
end

if doCheckMax
   if isscalar(maxVal)
      X(greaterThanMax) = maxVal;
   else
      X(greaterThanMax) = maxVal(greaterThanMax);
   end
end
end

function unittest
assert(all(csmu.bound(1:10, 0, 5, 'TestValue_1') ...
   == [1:5, 5, 5, 5, 5, 5]));

assert(all(csmu.bound(1:10, flip(1:10), 10, 'TestValue_2') ...
   == [10 9 8 7 6 6 7 8 9 10]));

assert(all(csmu.bound(1:10, 3, csmu.bound((1:10) - 3, 4, +inf)) ...
   == [3 3 3 4 4 4 4 5 6 7]));
end

