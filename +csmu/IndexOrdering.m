classdef IndexOrdering 
   enumeration
      XY
      ROWCOL
   end
   
   methods
      function out = toXY(self, in, varargin)
         switch self
            case csmu.IndexOrdering.XY
               out = in;               
            case csmu.IndexOrdering.ROWCOL
               out = swapDims(in, varargin{:});
         end
      end
      
      function out = toRowCol(self, in, varargin)
         switch self
            case csmu.IndexOrdering.XY
               out = swapDims(in, varargin{:});               
            case csmu.IndexOrdering.ROWCOL
               out = in;
         end
      end           
   end
end

function inputType = classifyInputType(in)
if isvector(in)
   if isscalar(in)
      inputType = csmu.IndexType.SCALAR;
   else
      inputType = csmu.IndexType.VECTOR;
   end
else
   if ismatrix(in) && any(size(in, 2) == [2, 3])
      inputType = csmu.IndexType.POINT_LIST;      
   else
      inputType = csmu.IndexType.ARRAY;
   end
end
end

function out = swapDims(in, varargin)
L = csmu.Logger(['csmu.', mfilename]);
ip = inputParser;
ip.addOptional('InputType', [], @(x) ischar(x) || isstring(x) ...
   || isa(x, 'csmu.IndexType'));
ip.parse(varargin{:});
inputType = ip.Results.InputType;

if isempty(inputType)
   inputType = classifyInputType(in);
   L.warn(['Auto classifying input as "%s"; pass a `csmu.IndexType` ', ...
      'explicitly to suppress this warning.'], inputType);
end

oldOrder = 1:2;
newOrder = fliplr(oldOrder);

switch inputType
   case csmu.IndexType.SCALAR
      out = in;
      
   case csmu.IndexType.VECTOR
      out = in;
      out(oldOrder) = out(newOrder);
      
   case csmu.IndexType.ARRAY
      numDims = ndims(in);
      ordering = 1:numDims;
      ordering(oldOrder) = ordering(newOrder);
      out = permute(in, ordering);
      
   case csmu.IndexType.POINT_LIST
      out = in;
      out(:, oldOrder) = out(:, newOrder);
end
end