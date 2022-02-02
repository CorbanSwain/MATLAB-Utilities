function out = cachedPrctile(varargin)

L = csmu.Logger(['csmu.ImageEvalMethod.', mfilename()]);

persistent resultsCache

if nargin == 1 && csmu.validators.scalarStringLike(varargin{1}) ...
      && strcmpi(varargin{1}, 'clear')
   resultsCache = [];
   L.debug('Cleared `resultsCache`.');
   return
end

if isempty(resultsCache)   
   resultsCache = cell.empty(0, 2);
end

cacheLength = size(resultsCache, 1);
for iEntry = 1:cacheLength
   [entryArgs, entryResult] = resultsCache{iEntry, :};
   if isequal(varargin, entryArgs)      
      L.debug('Using cached value for prctile computation.');
      out = entryResult;
      return
   end
end

L.debug('Computing and caching result of prctile computation.');
out = prctile(varargin{:});

resultsCache = [resultsCache; {varargin, out}];
end