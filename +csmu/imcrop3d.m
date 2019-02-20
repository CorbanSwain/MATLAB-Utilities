function Icrop = imcrop3d(I, box)

xmin = box(1, 1);
xmax = box(1, 2);
ymin = box(2, 1);
ymax = box(2, 2);
zmin = box(3, 1);
zmax = box(3, 2);

Icrop = I(ymin:ymax, xmin:xmax, zmin:zmax, :);
end