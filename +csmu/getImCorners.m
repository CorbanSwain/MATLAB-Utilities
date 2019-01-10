function corners = getImCorners(sz)
if ~isa(sz, 'imref3d')
   ref = imref3d(sz);
else
   ref = sz;
end
corners = zeros(8, 3);
for iCorner = 1:8
   [i1, i2, i3] = ind2sub([2 2 2], iCorner);
   corners(iCorner, :) = [ ...
      ref.XWorldLimits(i1), ...
      ref.YWorldLimits(i2), ...
      ref.ZWorldLimits(i3)];
end