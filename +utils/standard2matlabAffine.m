function T = standard2matlabAffine(T)
T = T';
sz = size(T);
if isequal(sz, [3 3])
   T = affine2d(T);
elseif isequal(sz, [4 4])
   T = affine3d(T);
else
   error('Unexpected size for passed tform, must be 2D or 3D affine matrix.');
end
end