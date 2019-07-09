function rgbImage = gray2rgb(I, colormap, varargin)
%% Function Metadata
fcnName = strcat('csplot.', mfilename);
L = csmu.Logger(fcnName);


%% Parsing Inputs
L.trace('Parsing inputs');
parserSpec = {
   {'p', 'ColorLimits', []}
   {'p', 'DoScaled', []}
};
ip = csmu.constructInputParser(parserSpec, 'Name', fcnName, 'Args', varargin);
inputs = ip.Results;


%% Computation
cmap = csplot.colormap(colormap);
numColors = size(cmap, 1);
indexImage = I;
if ~isempty(inputs.ColorLimits)
   if ~isfloat(indexImage)
      indexImage = double(indexImage);
   end
   indexImage = (indexImage - inputs.ColorLimits(1)) ...
      / diff(inputs.ColorLimits);
elseif inputs.DoScaled
   indexImage = csmu.fullscaleim(indexImage);
end
indexImage = round((indexImage * (numColors - 1)) + 1);
rgbImage = ind2rgb(indexImage, cmap);
end

function outputImage = ind2rgb(I, cmap)
if ~isfloat(I)
   % convert to one-indexed
   I = double(I) + 1;
end

nChannels = size(cmap, 2);
outChannels = cell(1, nChannels);
[outChannels{:}] = deal(zeros(size(I)));

for iChannel = 1:nChannels
   mapLookup = cmap(:, iChannel);
   outChannels{iChannel}(:) = mapLookup(I);
end

outputImage = csmu.Image;
outputImage.ChannelDim = 3;
outputImage.Channels = outChannels;
outputImage = outputImage.I;
end