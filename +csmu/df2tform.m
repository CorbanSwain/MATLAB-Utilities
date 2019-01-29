function tform = df2tform(rotation, translation, doReverse)
%DF2TFORM converts rotation and translation vectors to an affine3d object
%
% See also DFTRANSFORM
L = csmu.Logger('csmu.df2tform');

switch nargin
  case 2
    doReverse = false;
  case 3
  otherwise
    L.error(['Unexpected number of arguments 2 or 3 expected but %d ' ...
           'were passed'], nargin)
end

nDim = length(translation);
assert(any(nDim == [2 3]));

DIM_ORDER = [2 1];

% generating rotation matrices
if nDim == 2
   assert(isscalar(rotation));
   R = rotz(rotation);
   T = eye(3);
   T(3, 1:2) = translation(DIM_ORDER);
   tform = affine2d(R * T);
else   
   R1 = roty(rotation(1)); % dim 1 - y rotation
   R2 = rotx(rotation(2)); % dim 2 - x rotation
   R3 = rotz(rotation(3)); % dim 3 - z rotation
   [R, T] = deal(eye(4));
   R(1:3, 1:3) = R1 * R2 * R3; % rotating about y (dim1) then x (dim2)
   % then z (dim3).
   T(4, 1:3) = translation([DIM_ORDER 3]); % generating translation matrix
   tform = affine3d(R * T); % rotation before translation
end

if doReverse
   tform = tform.invert;
else
end
