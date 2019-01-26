function sizeCell = parseSizeArgs(varargin)
if length(varargin) == 1
   sizeCell = varargin{1};
   assert(isvector(sizeCell) || isempty(sizeCell));
   if isempty(sizeCell)
      sizeCell = {};
   elseif length(sizeCell) == 1
      sizeCell = {sizeCell, sizeCell};
   else
      sizeCell = num2cell(sizeCell);
   end
else
   sizeCell = varargin;
end
end