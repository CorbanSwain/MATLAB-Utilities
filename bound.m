function X = bound(X, min, max, name)
%BOUND Bound between a min and max.
%
%BOUND(X, min, max) will reduce all items in X greater than max to max,
%and less than min to min. X can be a scalar, vector, or matrix. 
%
%BOUND(X, min, max, name) behaves as BOUND(X, min, max) but will also
%display a warning message if truncating of values is necessary. name is a
%char array or string used in the warning message.
%
%by Corban Swain, 2017

switch nargin
    case 3
        warn = false;
    case 4
        warn = true;
    otherwise
        error('Unexpected number of arguments.');
end

lessThanMin = X < min;
greaterThanMax = X > max;

if warn
    if any(lessThanMin)
        warning('%s cannot be smaller than %d, truncating value(s).', ...
                name, min);
    end
    if any(greaterThanMax)
        warning('%s cannot be larger than %d, truncating value(s).', ...
                name, max);
    end
end

X(lessThanMin) = min;
X(greaterThanMax) = max;
end

