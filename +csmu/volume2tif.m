function volume2tif(V, filepath, varargin)
% converts a 3d array, V, to a tif stack at the specified file path
% V can also be a volume struct of length 3 with each of the color chanels

if nargin == 0
   unittest
   return;
end

L = csmu.Logger('csmu.volume2tif');

ip = inputParser;
ip.addParameter('ColorDim', 4);
ip.addParameter('Version', 2);
ip.addParameter('Class', '');
ip.addParameter('Compression', Tiff.Compression.PackBits);
ip.addParameter('PlanarConfiguration', Tiff.PlanarConfiguration.Chunky);
ip.addParameter('Photometric', []);
ip.addParameter('WarnOverwrite', false);
ip.addParameter('DoFullScale', false);
ip.parse(varargin{:});
colorDim = ip.Results.ColorDim;
processVersion = ip.Results.Version;
outputClass = ip.Results.Class;
tiffCompression = ip.Results.Compression;
tiffPlanarConfig = ip.Results.PlanarConfiguration;
tiffPhotometric = ip.Results.Photometric;
doWarnOverwrite = ip.Results.WarnOverwrite;
doFullScale = ip.Results.DoFullScale;

% TODO - check for and add support for other file formats
% TODO - add additional input argument to handle casting to uint8 and other
% formats automatically

% check if file exists
if doWarnOverwrite
   if exist(filepath, 'file')
      L.warn(['A file already exists at the given path; it will be ', ...
         'overwritten.']);
   end
end

[~,~,fileext] = fileparts(filepath);
if isempty(fileext)
   L.debug('No file extension given, assuming ''.tif''.');
   filepath = strcat(filepath, '.tif');
else
   L.assert(any(strcmpi(fileext, {'.tif', '.tiff'})), ...
      'Only writting of ''.tif'' files is supported.');
end

% regularize the input to M X N X [colors] X pages array 
if iscell(V)
   V = cat(4, V{:});
   colorDim = 4;
end

switch ndims(V)   
   case 2
      % pass
   
   case 3 % greyscale volume
      V = permute(V, [1 2 4 3]);
      
   case 4 % color volume
      switch colorDim
         case 3
            % pass
         case 4
            V = permute(V, [1 2 4 3]);
         otherwise
            L.error('ColorDim can only be either 3 or 4');
      end
   
   otherwise
      L.error('Input image must have either 2, 3, or 4 dimsions');
end

if doFullScale
   L.trace('Converting image to full scale.');
   if ~isfloat(V)
      V = double(V);
   end
   V = csmu.fullscaleim(V);
end

% convert from float if need be
if ~(isa(V, outputClass) || isempty(outputClass))
   V = csmu.double2im(V, outputClass);
end

switch processVersion
   case 1
      % initial write to tif file
      imwrite(V(:, :, :, 1), filepath);
      
      % add all layers to tif stack
      nPages = size(V, 4);
      for iPage = 2:nPages
         imwrite(V(:, :, :, iPage), filepath, 'WriteMode', 'append');
      end

   case 2
      tags = struct;      
      [tags.ImageLength, tags.ImageWidth, nChannels, nPages] = size(V);      
      tags.BitsPerSample = csmu.ImageDataType.var2bits(V);
      tags.SamplesPerPixel = nChannels;
      tags.Compression = tiffCompression;
      tags.PlanarConfiguration = tiffPlanarConfig;
      tags.Software = 'MATLAB';
      tags.RowsPerStrip = calcRowsPerStrip(tags.ImageWidth, ...
         tags.BitsPerSample, tags.SamplesPerPixel);
      if isempty(tiffPhotometric)
         if nChannels == 3
            tiffPhotometric = Tiff.Photometric.RGB;
         elseif nChannels == 1
            tiffPhotometric = Tiff.Photometric.MinIsBlack;
         else
            L.error('Cannot determine proper tiff Photometric.');
         end
      end
      L.debug(tags, 'tags');
      tags.Photometric = tiffPhotometric;      
      t = Tiff(filepath, 'w');
      cleanup = onCleanup(@() t.close);      
      for iPage = 1:nPages         
         t.setTag(tags);
         t.write(V(:, :, :, iPage));
         t.writeDirectory;
      end
      clear('cleanup');
end
end

function rps = calcRowsPerStrip(imageWidth, bitsPerSample, samplesPerPixel)
L = csmu.Logger('csmu.vol2tiff>calcRowsPerStrip');
iw = imageWidth;
bps = bitsPerSample;
spp = samplesPerPixel;
% each strip should be about 8K (65536 bits)
rps = round(65536 / bps / iw) * 4;
L.debug('RPS = %d', rps);
end

function unittest
L = csmu.Logger('csmu.volume2tiff>unittest');
cls = 'uint8';
V = randi(intmax(cls), 1215, 960, 1, 801, cls);
f = cell(1, 2);

t = tic;
f{1} = 'F:/test_v1.tif';
csmu.volume2tif(V, f{1}, 'ColorDim', 3, 'Version', 1);
L.info('V1, Write took %7.3f seconds', toc(t));

t = tic;
f{2} = 'F:/test_v2.tif';
csmu.volume2tif(V, f{2}, 'ColorDim', 3, 'Version', 2);
L.info('V2, Write took %7.3f seconds', toc(t));

Vout = cell(2, 1);
t = tic;
Vout{1} = csmu.volread(f{1}, 'Version', 1);
L.info('V1, Read took %7.3f seconds', toc(t));
L.info('Volume size: [%s]', num2str(size(Vout{1})));
L.info('Volume class: %s', class(Vout{1}));
if size(V, 3) > 1
   Vout{1} = permute(Vout{1}, [1 2 4 3]);
end

t = tic;
Vout{2} = csmu.volread(f{2}, 'Version', 2);
L.info('V2, Read took %7.3f seconds', toc(t));
L.info('Volume size: [%s]', num2str(size(Vout{2})));
L.info('Volume class: %s', class(Vout{2}));

L.info('Equal when reloaded? : %s', csmu.bool2string(isequal(Vout{:})));
end
