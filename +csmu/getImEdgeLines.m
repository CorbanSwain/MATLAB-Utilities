function linePoints = getImEdgeLines(refSpec)
ref = csmu.ImageRef(refSpec);

limits = cat(2, ...
   ref.XWorldLimits', ...
   ref.YWorldLimits', ...
   ref.ZWorldLimits');

linePoints = zeros(24, 3);
defaultSel = 1:2;
for i = 1:12
   [idx, maxmin1, maxmin2] = ind2sub([3, 2, 2], i);
   notSel = 1:3;
   notSel(idx) = [];
   lne = zeros(2, 3);
   lne(:, notSel(1)) = repmat(limits(maxmin1, notSel(1)), 1, 2);
   lne(:, notSel(2)) = repmat(limits(maxmin2, notSel(2)), 1, 2);
   lne(:, idx) = limits(:, idx);
   sel = defaultSel + ((i - 1) * 2);
   linePoints(sel, :) = lne;
end
end