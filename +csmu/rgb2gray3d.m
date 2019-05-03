function Igray = rgb2gray3d(I, varargin)
%RGB2GRAY converts a color image into grayscale image for 2d and 3d images.

%% Defaults
DEFAULT_COLOR_WT = [0.2989, 0.5870, 0.1140];

%% Input Parsing
p = inputParser;
p.addOptional('ColorWeight', DEFAULT_COLOR_WT, ...
   @(x) isempty(x) || (isvector(x) && length(x) == 3));
p.parse(varargin{:});
colorwt = p.Results.ColorWeight;

%% Logging
L = csmu.Logger(['csmu', mfilename]);

%% Perform Conversion
switch ndims(I)
   case 2
      error('An RGB image must be passed.');
   case 3
      dim3Color = size(I, 3) == 3;
      if dim3Color
         Igray = rgb2gray(I);
      else
         L.error('A grayscale 3d image or improperly formated color 2d', ...
            'image was passed');
      end
   case 4
      dim3Color = size(I, 3) == 3;
      dim4Color = size(I, 4) == 3;
      if dim3Color && dim4Color
         colordim = 3;
      elseif dim3Color
         colordim = 3;
      elseif dim4Color
         colordim = 4;
      else
         L.error('No color channel dimension found.');
      end
      
      if colordim == 3
         Igray = I(:, :, 1, :) * colorwt(1) ...
            + I(:, :, 2, :) * colorwt(2) ...
            + I(:, :, 3, :) * colorwt(3);
         Igray = squeeze(Igray);
      elseif colordim == 4
         Igray = I(:, :, :, 1) * colorwt(1) ...
            + I(:, :, :, 2) * colorwt(2) ...
            + I(:, :, :, 3) * colorwt(3);
      else
         L.error('Invalid color channel dimension.');
      end
        
   otherwise
      L.error('Input image must be either a 2d or 3d color image.');
end
