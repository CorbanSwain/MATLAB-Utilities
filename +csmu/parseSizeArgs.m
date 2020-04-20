function sizeCell = parseSizeArgs(varargin)
if isempty(varargin)
   error('Size specification argument(s) must be passed.');
elseif length(varargin) == 1
   sizeSpec = varargin{1};
   assert(isnumeric(sizeSpec), 'Size specification must be numeric.')
   assert(isvector(sizeSpec) || isempty(sizeSpec), ...
      'Single size specification must be a vector or scalar.');   
   if isempty(sizeSpec)
      sizeCell = {};
   else
      assert(all(csmu.isint(sizeSpec)), 'All sizes must be integers.');
      assert(all(sizeSpec >= 0), 'All sizes must be non-negative.');
      if length(sizeSpec) == 1
         sizeCell = {sizeSpec, sizeSpec};
      else
         sizeCell = num2cell(sizeSpec(:)');
      end
   end
else
   csmu.cellmap(@(x) assert(isscalar(x) && csmu.isint(x) && (x >= 0), ...
      'All sizes must be non-negative scalar integers.'), varargin);
   sizeCell = varargin;
end
end