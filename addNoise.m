% addNoise

% adapted from code by YoungGyu Yoon, September 2018

function [varargout] = addNoise(I, quantumEffenciency, readNoise, ...
   photonsPerPixelPerSec, exposureTime, varargin)

if nargin == 0
   unittest;
   return
end

ip = inputParser;
ip.addParameter('OutputClass', class(I), @(x) ischar(x) && isvector(x));
ip.addParameter('FullScale', true, @(x) isscalar(x) && islogical(x));
ip.parse(varargin{:});
r = ip.Results;
outputClass = r.OutputClass;
doFullScale = r.FullScale;

if doFullScale
   I = double(I);
   I = I / max(I(:));
end
maxPhotonCount = photonsPerPixelPerSec * exposureTime * quantumEffenciency;
photonsImage = cast(maxPhotonCount * I, 'uint16');
totalPhotonCount = sum(photonsImage(:));

noisyPhotonsImage = cast(imnoise(photonsImage, 'poisson'), outputClass);
noisySensorImage = cast(readNoise * randn(size(photonsImage)), outputClass);
J = subplus((noisyPhotonsImage + noisySensorImage) / 2);
J = J / maxPhotonCount;

nargoutchk(1, 2);
switch nargout
   case 1
      varargout = {J};
   case 2
      varargout = {J, totalPhotonCount};
end
end

function unittest
I = im2double(imread('C:\Users\CorbanSwain\repos\temp\neuron.png'));
I = imresize(squeeze(I(:, :, 2) / max(I(:))), 1);

fh = figure(1);
ax = subplot(1, 2, 1, 'Parent', fh);
image(ax, utils.double2im(I, 'uint8'));

J = utils.addNoise(I, 0.5, 1, 300, 1/10);
ax = subplot(1, 2, 2, 'Parent', fh);
image(ax, utils.double2im(J, 'uint8'));
colormap(fh, 'gray');
end