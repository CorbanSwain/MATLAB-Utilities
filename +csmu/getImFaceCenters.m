function points = getImFaceCenters(refSpec)
ref = csmu.ImageRef(refSpec);

limits = cat(2, ...
   ref.XWorldLimits', ...
   ref.YWorldLimits', ...
   ref.ZWorldLimits');

center = csmu.getImCenter(ref);
points = zeros(6, 3);
for iFace = 1:6
   [idx, maxmin] = ind2sub([3, 2], iFace);
   point = center;
   point(idx) = limits(maxmin, idx);
   points(iFace, :) = point;      
end
end