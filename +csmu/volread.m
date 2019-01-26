function V = volread(filepath, varargin)
if nargin == 0
   unittest;
   return
end

ip = inputParser;
ip.addParameter('Version', 2)
ip.parse(varargin{:});
processVersion = ip.Results.Version;

% FIXME - Only TIFF files supported
% ensure filename ends in '.tif'
[~,~,fileext] = fileparts(filepath);
if ~strcmp(fileext, '.tif') && ~strcmp(fileext, '.tiff')
   filepath = strcat(filepath, '.tif');
end
assert(logical(exist(filepath, 'file')));

switch processVersion
   case 1     
      imInfo = imfinfo(filepath);
      nPages = length(imInfo);
      readPage = @(i) imread(filepath, 'Index', i);
      
      % grab first frame for proper class
      page1 = readPage(1);
      sz = arrayfun(@(i) size(page1, i), 1:3);
      V = zeros([sz(1:2), nPages, sz(3)], class(page1));
      V(:, :, 1, :) = page1;
      
      % grab the remaining pages, if there are any
      if nPages > 1
         for iPage = 2:nPages
            V(:, :, iPage, :) = readPage(iPage);
         end
      end

   case 2      
      t = Tiff(filepath);
      cleanup = onCleanup(@() close(t));
      sz = [t.getTag('ImageLength'), t.getTag('ImageWidth')];
      nBits = t.getTag('BitsPerSample');
      nChannels = t.getTag('SamplesPerPixel');
      nPages = 1;
      while ~t.lastDirectory
         t.nextDirectory;
         nPages = nPages + 1;
      end      
      t.setDirectory(1);
      V = zeros([sz, nChannels, nPages], csmu.ImageDataType.bits2class(nBits));
      V(:, :, :, 1) = t.read(); 
      for iPage = 2:nPages
         t.nextDirectory;
         V(:, :, :, iPage) = t.read();
      end
      clear('cleanup');
      if nChannels == 1
         V = permute(V, [1 2 4 3]);
      end            
end
end


function unittest
L = csmu.Logger('csmu.volread>unittest');
filepath = ['C:\data_1\corban_swain\projects\dual_view_reconstruction\', ...
   'working_software_data\03_reconstructed\190111_cs_zw_fly_and_reg\', ...
   '02_reg_beads_set\recon_3d_singleview_reg_beads_T23_C_rectN15_camera_1.tif'];

% filepath = ['C:\Users\CorbanSwain\Desktop\', ...
%     'recon_3d_singleview_reg_beads_T37_C_rectN15_camera_1.tif'];

t = tic;
V.v1 = csmu.volread(filepath, 'Version', 1);
L.info('Version 1 took: %6.3f seconds', toc(t));
L.info('Volume size: [%s]', num2str(size(V.v1)));
L.info('Volume class: %s', class(V.v1));

t = tic;
V.v2 = csmu.volread(filepath, 'Version', 2);
L.info('Version 2 took: %6.3f seconds', toc(t));
L.info('Volume size: [%s]', num2str(size(V.v2)));
L.info('Volume class: %s', class(V.v2));

L.info('equal? : %s', csmu.bool2string(isequal(V.v1, V.v2)))

end