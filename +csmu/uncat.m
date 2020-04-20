%UNCAT splits an array into a cell array along the supplied dimension.
%
%   Y = UNCAT(dim, X)
% 
%   Inputs
%      - dim (1, 1) {numeric, integer, > 0}
%      - X
%
%   Outputs
%      - Y: (1, :) cell

% Corban Swain, 2020

function Y = uncat(dim, X)
dimSize = size(X, dim);
dimsNeeded = max(ndims(X), dim);
splitSpec = csmu.cellmap(@(d) size(X, d), num2cell(1:dimsNeeded));
splitSpec{dim} = ones(1, dimSize);
Y = mat2cell(X, splitSpec{:});
Y = Y(:)';
end