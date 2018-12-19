function A=imresize4d(V,scale,tsize,ntype,npad)
% This function resizes a 3D image volume to new dimensions
% Vnew = imresize3d(V,scale,nsize,ntype,npad);
%
% inputs,
%   V: The input image volume
%   scale: scaling factor, when used set tsize to [];
%   nsize: new dimensions, when used set scale to [];
%   ntype: Type of interpolation ('nearest', 'linear', or 'cubic')
%   npad: Boundary condition ('replicate', 'symmetric', 'circular', 'fill', or 'bound')  
%
% outputs,
%   Vnew: The resized image volume
%
% example,
%   load('mri','D'); D=squeeze(D);
%   Dnew = imresize3d(D,[],[80 80 40],'nearest','bound');
%
% This function is written by D.Kroon University of Twente (July 2008)

% Check the inputs
if(exist('ntype', 'var') == 0), ntype='nearest'; end
if(exist('npad', 'var') == 0), npad='bound'; end
if(exist('scale', 'var')&&~isempty(scale)), tsize=round(size( squeeze(V(:,:,:,1)) )*scale); end
if(exist('tsize', 'var')&&~isempty(tsize)),  scale=(tsize./size(squeeze(V(:,:,:,1)))); end

% Make transformation structure   
T = makehgtform('scale',scale);
tform = maketform('affine', T);

% Specify resampler
R = makeresampler(ntype, npad);

% Resize the image volueme
for k=1:size(V,4),
    A(:,:,:,k) = tformarray( squeeze(V(:,:,:,k)), tform, R, [1 2 3], [1 2 3], tsize, [], 0);
end

