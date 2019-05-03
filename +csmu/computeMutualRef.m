function mutualRef = computeMutualRef(refList, varargin)
ip = inputParser;
ip.addParameter('Method', 'Max', @(x) any(strcmpi(x, {'Max', 'Min'})));
ip.parse(varargin{:});
ip = ip.Results;
method = lower(ip.Method);

L = csmu.Logger(strcat('csmu.', mfilename));

nRefs = numel(refList);
switch class(refList)
   case 'cell'
      refs(1, nRefs) = csmu.ImageRef;
      for iRef = 1:length(refList)
         refs(iRef) = csmu.ImageRef(refList{iRef});
      end
      
   case 'csmu.ImageRef'
      refs = refList;
      
   otherwise
      L.error('Unexpected input type.');
end

worldLims = cell(1, nRefs);
[worldLims{:}] = refs.WorldLimits;
combinedWorldLimits = csmu.cellmap(@(wl) [wl{:}], worldLims);
combinedWorldLimits = cat(1, combinedWorldLimits{:});

% FIXME - make agnostic to 3d vs 2d
worldLower = combinedWorldLimits(:, [1 3 5]);
worldUpper = combinedWorldLimits(:, [2 4 6]);

switch method
   case 'max'
      worldLower = min(worldLower, [], 1);
      worldUpper = max(worldUpper, [], 1);      
      worldSize = ceil(worldUpper - worldLower);
   case 'min'
      worldLower = max(worldLower, [], 1);
      worldUpper = min(worldUpper, [], 1);
      worldSize = floor(worldUpper - worldLower);
end
worldCenter = mean([worldLower; worldUpper], 1);
worldUpper = worldCenter + (worldSize / 2);
worldLower = worldCenter - (worldSize / 2);
worldSize = csmu.IndexOrdering.XY.toRowCol(worldSize, csmu.IndexType.VECTOR);

% FIXME - use cellmaping to do this
mutualRef = csmu.ImageRef(worldSize, [worldLower(1), worldUpper(1)], ...
   [worldLower(2), worldUpper(2)], [worldLower(3), worldUpper(3)]);
end