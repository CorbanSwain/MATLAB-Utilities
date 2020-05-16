function [varargout] = colormap(varargin)
narginchk(1, 2);
L = csmu.Logger(['csplot.' mfilename]);
cmapSpec = varargin{end};
if csmu.validators.stringLike(cmapSpec)
   cmapName = char(lower(cmapSpec));
   cmapDirs = {fullfile(csmu.extensionsDir, 'biguri_colormaps'), ...
      fullfile(csmu.extensionsDir, 'twilight_colormap')};
   cleanup = onCleanup(@() rmpath(cmapDirs{:}));
   addpath(cmapDirs{:});
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
         
      case {'twilight'}
         cm = twilight();
         
      case {'twilight_shifted'}
         cm = twilight();
         cmLength = size(cm, 1);
         cm = circshift(cm, ceil(cmLength / 2), 1);
         
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
         'dimensions; size is [%s].'), num2str(size(cmapMatrix)));
   end
   cm = cmapMatrix;
end

if nargin > 1
   colormap(varargin{1}, cm);
end

if nargout == 0
   fig = gcf();
   colormap(fig, cm);
else
   varargout = {cm};
end
end