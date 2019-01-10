function I = loadAnyImage(imPath)
L = csmu.Logger('csmu.loadAnyImage');
[~, filename, fileext] = fileparts(imPath);

switch fileext
   case '.mat'
      matfile = load(imPath);
      matfileFields = fieldnames(matfile);
      numFields = length(matfileFields);
      if  numFields < 1
         L.error('No variables found in the passed .mat file.');
      elseif numFields == 1
         I = matfile.(matfileFields{1});
      else
         L.error(['Too many variables in the passed .mat file; only one ', ...
            'var is allowed for loadAnyImage, otherwise use LOAD.']);
      end
         
   case '.nii'
      I = niftiread(imPath);
      
   case '.tif'
      I = csmu.volread(imPath);
   
   case '.tiff'
      I = csmu.volread(imPath);
      
   otherwise
      L.error('Unsupported image file format.');
end