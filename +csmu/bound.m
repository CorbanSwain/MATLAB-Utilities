function X = bound(X, min, max, name)
%BOUND Bound between a min and max.
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

doCheckMin = ~isempty(min);
doCheckMax = ~isempty(max);

if doCheckMin
   lessThanMin = X < min;
end

if doCheckMax
   greaterThanMax = X > max;
end

if doWarn
   if doCheckMin && any(lessThanMin)
      warning('%s cannot be smaller than [%s], truncating value(s).', ...
         name, num2str(min));
   end
   if doCheckMax && any(greaterThanMax)
      warning('%s cannot be larger than [%s], truncating value(s).', ...
         name, num2str(max));
   end
end

if doCheckMin
   if isscalar(min)
      X(lessThanMin) = min;
   else
      X(lessThanMin) = min(lessThanMin);
   end
end

if doCheckMax
   if isscalar(max)
      X(greaterThanMax) = max;
   else
      X(greaterThanMax) = max(greaterThanMax);
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

