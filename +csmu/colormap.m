function cm = colormap(varargin)
narginchk(1, 2);
L = csmu.Logger(['csmu.' mfilename]);
name = varargin{length(varargin)};
name = char(lower(name));
cmapDir = fullfile(csmu.extensionsDir, 'biguri_colormaps');
cleanup = onCleanup(@() rmpath(cmapDir));
addpath(cmapDir);
switch name
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
    
   otherwise
      cm = colormap(name);      
end

if nargin > 1
   colormap(varargin{1}, cm);
end
end