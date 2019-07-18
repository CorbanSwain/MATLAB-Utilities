function imshow3d(varargin)
extensionPath = fullfile(csmu.extensionsDir, 'imshow3D');
cleanup = onCleanup(@() rmpath(extensionPath));
addpath(extensionPath);
if length(varargin) < 3
   newArgs = cell(1, 3);
   newArgs(1:length(varargin)) = varargin;
   newArgs{3} = csmu.colormap('inferno');
end
imshow3D(newArgs{:});
end