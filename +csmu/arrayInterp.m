%ARRAYINTERP Interpolates an array along a given dimension by a given factor.
%Output size is the same as input, except along the interpolated 
%dimension for which the new size is: factor * (size(A, dim) - 1) + 1.
%
% See also INTERPSIZE and GRIDDEDINTERPOLANT.

% Corban Swain, 2018

function Ainterp = arrayInterp(A, dim, factor, method)
L = csmu.Logger('csmu.arrayInterp');

switch nargin
   case 3, method = 'linear';
   case 4
   otherwise
      L.error(strcat('Unexpected number of arguments, 3 or 4 expected', ...
         ' but %d were recieved.'), nargin);
end

if factor == 1
   Ainterp = A;
   return;
end

nDims = max(ndims(A), dim);
outVectors = cell(nDims, 1);

for iDim = 1:nDims
   if iDim == dim, step = (1 / factor);
   else, step = 1; end  
   outVectors{iDim} = 1:step:size(A, iDim);
end

Vquery = griddedInterpolant(A, method);
Ainterp = Vquery(outVectors);
end