function imshow3d(varargin)
extensionPath = fullfile(csmu.extensionsDir, 'imshow3D');
cleanup = onCleanup(@() rmpath(extensionPath));
addpath(extensionPath);
if length(varargin) < 3
   imShow3dArgs = cell(1, 3);
   imShow3dArgs(1:length(varargin)) = varargin;
   imShow3dArgs{3} = csmu.colormap('magma');
else
   imShow3dArgs = varargin;
end
imshow3D(imShow3dArgs{:});
end