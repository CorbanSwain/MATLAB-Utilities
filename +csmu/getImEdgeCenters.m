function points = getImEdgeCenters(sz)
if ~isa(sz, 'imref3d')
   ref = imref3d(sz);
else
   ref = sz;
end

centers = csmu.getImCenter(ref);
limits = cat(2, ...
   ref.XWorldLimits', ...
   ref.YWorldLimits', ...
   ref.ZWorldLimits');

points = zeros(12, 3);
for i = 1:12
   [idx, maxmin1, maxmin2] = ind2sub([3, 2, 2], i);
   point = centers;
   notSel = 1:3;
   notSel(idx) = [];
   point(notSel) = [limits(maxmin1, notSel(1)), limits(maxmin2, notSel(2))];
   points(i, :) = point;
end
end