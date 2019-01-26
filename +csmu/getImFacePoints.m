function points = getImFacePoints(refSpec, numDivisions)
ref = csmu.ImageRef(refSpec);

numFacePoints = (numDivisions + 1) ^ 2;
points = zeros(numFacePoints * 6, 3);

limits = cat(2, ...
   ref.XWorldLimits', ...
   ref.YWorldLimits', ...
   ref.ZWorldLimits');
baseSel = (1:numFacePoints) - 1;
for iFace = 1:6
   facePoints = zeros(numFacePoints, 3);
   [idx, maxmin] = ind2sub([3, 2], iFace);
   lock = limits(maxmin, idx);
   notSel = 1:3;
   notSel(idx) = [];
   v1 = limits(:, notSel(1))';
   v2 = limits(:, notSel(2))';
   v1 = linspace(v1(1), v1(2), numDivisions + 1);
   v2 = linspace(v2(1), v2(2), numDivisions + 1);
   [vv1, vv2] = meshgrid(v1, v2);
   facePoints(:, idx) = lock;
   facePoints(:, notSel) = [vv1(:), vv2(:)];
   points(baseSel + (((iFace - 1) * numFacePoints) + 1), :) = facePoints;
end
points = unique(points, 'rows');
end