function points = getImFaceCenters(sz)
if ~isa(sz, 'imref3d')
   ref = imref3d(sz);
else
   ref = sz;
end

limits = cat(2, ...
   ref.XWorldLimits', ...
   ref.YWorldLimits', ...
   ref.ZWorldLimits');

center = utils.getImCenter(ref);
points = zeros(6, 3);
for iFace = 1:6
   [idx, maxmin] = ind2sub([3, 2], iFace);
   point = center;
   point(idx) = limits(maxmin, idx);
   points(iFace, :) = point;      
end
end