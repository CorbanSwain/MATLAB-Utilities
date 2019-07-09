function cm = colormap(varargin)
narginchk(1, 2);
L = csmu.Logger(['csplot.' mfilename]);
cmapSpec = varargin{end};
if csmu.validators.stringLike(cmapSpec)
   cmapName = char(lower(cmapSpec));
   cmapDir = fullfile(csmu.extensionsDir, 'biguri_colormaps');
   cleanup = onCleanup(@() rmpath(cmapDir));
   addpath(cmapDir);
   primaries = {'red', 'green', 'blue'};
   secondaries = {'cyan', 'magenta', 'yellow'};
   switch cmapName
      case {'magma', 'a'}
         cm = magma();
         
      case {'inferno', 'b'}
         cm = inferno();
         
      case {'plasma', 'c'}
         cm = plasma();
         
      case {'viridis', 'd'}
         cm = viridis();
         
      case {'grey', 'gray'}
         cm = colormap('gray');
         
      case primaries
         cmaplength = 256;
         cm = zeros(cmaplength, 3);
         ramp = linspace(0, 1, cmaplength)';
         switch cmapName
            case {'red'}
               cm(:, 1) = ramp;
               
            case {'green'}
               cm(:, 2) = ramp;
               
            case {'blue'}
               cm(:, 3) = ramp;
         end
         
      case secondaries
         clear('cleanup');
         switch cmapName
            case {'cyan'}
               clear('cleanup')
               cm = csplot.colormap('green') + csplot.colormap('blue');
               
            case {'magenta'}
               cm = csplot.colormap('red') + csplot.colormap('blue');
               
            case {'yellow'}
               cm = csplot.colormap('red') + csplot.colormap('green');
         end
         
      otherwise
         cm = colormap(cmapName);
   end
elseif isnumeric(cmapSpec)
   cmapMatrix = cmapSpec;
   if ~ismatrix(cmapMatrix) || size(cmapMatrix, 2) ~= 3
      L.warn(strcat('Provided numeric colormap does not have typical ', ...
         'dimensions [%s]'), num2str(size(cmapMatrix)));
   end
   cm = cmapMatrix;
end

if nargin > 1
   colormap(varargin{1}, cm);
end
end