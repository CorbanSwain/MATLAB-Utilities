% CIRC - n-dimensional circ function, uses row-column ordering.

% Corban Swain, 2019

function output = circ(r, arraySize)
nDims = length(arraySize);
r = ones(1, nDims) .* r;
maxComputeSize = (r * 2) + 2;
computeSize = min(maxComputeSize, arraySize);
computeSize = computeSize + mod(computeSize + arraySize, 2);
padSize = (arraySize - computeSize) / 2;

[dimVectors, dimGrid] = deal(cell(1, nDims));
[dimVectors{:}] = csmu.zeroCenterVector(computeSize);
[dimGrid{:}] = ndgrid(dimVectors{:});

radiusGrid = csmu.cellreduce(@(out, x, ri) out + ((x .^ 2) ./ (ri .^ 2)), ...
   dimGrid, num2cell(r), 0);
output = radiusGrid <= 1;
output = padarray(output, padSize, false);
end