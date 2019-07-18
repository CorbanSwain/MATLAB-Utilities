%CSMU.SPIRALINDEX Generates an inward spiraling index into an matrix.
%
%
%   Syntax:
%   -------
%   [rowIndexes, colIndexes] = CSMU.SPIRALINDEX(arraySize) takes in a
%   two element vector, arraySize, and generates a list of row and colum
%   indexes for iterating through every element of a matrix of arraySize from 
%   the top left corner (1, 1) to the center of the matrix in a clockwise, 
%   inward spiraling fashion.
%
%   [rowIndexes, colIndexes] = CSMU.SPIRALINDEX(n) returns the spiral index 
%   into an n-by-n matrix. Equivalent to CSMU.SPIRALINDEX([n, n]).
%
%
%   Inputs:
%   -------
%      arraySize - a two element numeric vector or a scalar integer
%                  (indicating a square matrix).
%                  * type: must contain non-negative integers
%
%
%   Outputs:
%   --------
%      rowIndexes - The indexes for indexing into the rows of a matrix of 
%                   arraySize in a spiraling order. See Example 1.
%                   * size: [1, prod(arraySize * [1, 1])]
%      
%      colIndexes - The indexes for indexing into the columns of a matrix of 
%                   arraySize in a spiraling order. See Example 1.
%                   * size: [1, prod(arraySize * [1, 1])];
%      
%
%   Notes:
%   ------
%   - This function is useful for iterating through phase space in image
%     deconvolution operations.
%
%
%   Example 1:
%   --------
%   >> arrSize = [3, 4];
%   >> [ri, ci] = csmu.spiralIndex(arrSize)
%   
%   ri = 
%
%         1     1     1     1     2     3     3     3     3     2     2     2
%   
%      
%   ci =
%      
%         1     2     3     4     4     4     3     2     1     1     2     3
%     
%   >> x = zeros(arrSize);
%   >> for i = 1:numel(x), x(ri(i), ci(i)) = i; end
%   >> x
%
%   x = 
%
%        1     2     3     4
%       10    11    12     5
%        9     8     7     6
%
%
%   See also SPIRAL.

% Corban Swain, 2019

function [rowIndexes, colIndexes] = spiralIndex(arraySize)

%% Function Metadata
fcnName = strcat('csmu.', mfilename);
L = csmu.Logger(fcnName);

%% Input Handling
L.assert(isvector(arraySize) && any(length(arraySize) == [1, 2]), ...
   'arraySize must be a vector of length 1 or 2 (size(arraySize) = [%s]).', ...
   num2str(size(arraySize)));
L.assert(all(arraySize >= 0), ...
   'arraySize must only contain non-negative integers (arraySize = [%s]).', ...
   num2str(arraySize));

if isscalar(arraySize)
   arraySize = [1, 1] * arraySize;
end

%% Computation
[rowIndexes, colIndexes] = spiralIndexHelper(arraySize);

end

function [rowIndexes, colIndexes] = spiralIndexHelper(arraySize)
% SPIRALINDEXHELPER recursive helper function for CSMU.SPIRALINDEX.

nRows = arraySize(1);
nCols = arraySize(2);

if nRows > 1 && nCols > 1
   oneLessForCols = ones(1, nCols - 1);
   oneLessForRows = ones(1, nRows - 1);
   
   rowIndexes = [...
      oneLessForCols, ...
      1:1:(nRows - 1), ...
      oneLessForCols * nRows, ...
      nRows:-1:2];
   colIndexes = [...
      1:1:(nCols - 1), ...
      oneLessForRows * nCols, ...
      nCols:-1:2, ...
      oneLessForRows];
   
   [remainingRowIndexes, remainingColIndexes] = ...
      spiralIndexHelper(arraySize - 2);
   rowIndexes = [rowIndexes, remainingRowIndexes + 1];
   colIndexes = [colIndexes, remainingColIndexes + 1];
   
elseif nRows == 0 || nCols == 0
   rowIndexes = [];
   colIndexes = [];
   
else
   if nRows == 1
      rowIndexes = ones(1, nCols);
   else
      rowIndexes = 1:nRows;
   end
   
   if nCols == 1
      colIndexes = ones(1, nRows);
   else
      colIndexes = 1:nCols;
   end
end
end