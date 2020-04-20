%CAT
%
%   Y = cat(dim, X) combines the elements of cell vector X into an array Y.
%
%   Inputs
%   - dim (1, 1) {numeric, integer, > 0}
%   - X (1, :) cell
%
%   Outputs
%   - Y

% Corban Swain, 2020

function Y = cat(dim, X)
Y = cat(dim, X{:});
end