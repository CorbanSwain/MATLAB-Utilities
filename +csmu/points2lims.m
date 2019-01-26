function lims = points2lims(varargin)
allPoints = cat(1, varargin{:});
lims = cat(1, min(allPoints, [], 1), max(allPoints, [], 1));