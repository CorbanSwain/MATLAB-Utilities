function I = loadAnyImage(imPath, varargin)
funcName = strcat('csmu.', mfilename);
L = csmu.Logger(funcName);

parserSpec = {{'p', 'Slice', []}};
ip = csmu.constructInputParser(parserSpec, 'Name', funcName, 'Args', varargin);
ip = ip.Results;

[~, ~, fileext] = fileparts(imPath);
L.assert(logical(exist(imPath, 'file')), 'Image file does not exist.');

switch lower(fileext)
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
      
   case {'.tif', 'tiff'}
      I = csmu.volread(imPath, 'Slice', ip.Slice);
      
   otherwise
      try
         L.warn(['Falling back to use builtin `imread`, some components ', ...
            'of the image may not be loaded properly.']);
         I = imread(imPath);
      catch ME
         causeME = MException('csmu:loadAnyImage:unsupportedFormat', ...
            sprintf(['Passed image format "%s" is not supported or could ', ...
            'not be read'], fileext));
         ME = ME.addCause(causeME);
         L.logException(csmu.LogLevel.ERROR, ME);
         rethrow(ME);
      end      
end

end