function S = structmerge(varargin)
if nargin
   cellarrs = csmu.cellmap(@namedargs2cell, varargin);
   S = csmu.argscell2struct(cat(2, cellarrs{:}));
else
   S = struct();
end
end