function Icrop = imcrop3d(I, box, varargin)
ip = inputParser;
ip.addParameter('Method', '', @(x) any(strcmpi({'limits', 'crop'}, x)));
ip.parse(varargin{:});
ip = ip.Results;
method = ip.Method;

L = csmu.Logger(strcat('csmu.', mfilename));

xmin = box(1, 1);
xmax = box(1, 2);
ymin = box(2, 1);
ymax = box(2, 2);
zmin = box(3, 1);
zmax = box(3, 2);

if isempty(method)
   if xmax > (size(I, 2) / 2)      
      method = 'limits';
   else
      method = 'crop';
   end
   L.warn(strcat('Automatically using "%s" method for `imcrop3d`; specify ', ...
      'the `Method` parameter to suppress this warning.'), method);
end

switch lower(method)
   case 'limits'     
      Icrop = I(ymin:ymax, xmin:xmax, zmin:zmax, :);
   case 'crop'
      Icrop = I((1 + ymin):(end - ymax), (1 + xmin):(end - xmax), ...
         (1 + zmin):(end - zmax), :);
end
       
end