function r = range(X, dim)
if nargin == 1
   dim = ndims(X);
end

switch dim
   case 'all'
      catdim = 2;
   otherwise
      catdim = dim;
end

r = cat(catdim, min(X, [], dim), max(X, [], dim));
end