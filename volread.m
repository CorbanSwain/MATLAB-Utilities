function V = volread(fPath)
imInfo = imfinfo(fPath);
nFrames = length(imInfo);
imSize = [imInfo(1).Height, imInfo(1).Width];
V = zeros([imSize, nFrames]);
for iFrame = 1:nFrames
   V(:,:,iFrame) = imread(fPath, 'Index', iFrame);
end