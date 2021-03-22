function I = sumProject(V, varargin)
%% Unit Test
if nargin == 0
   unittest;
   return
end

%% Parse Inputs
%%% Check Inputs
p = inputParser;
p.addOptional('dim', 3, @(x) any(x == (1:3)));
p.KeepUnmatched = true;
p.parse(varargin{:});


%%% Assign Inputs
dim = p.Results.dim;
if ndims(V) == 4 && size(V, 4) == 3
   isColorIm = true;
else 
   isColorIm = false;
end

%% Perform Projection
isVolumeInt = isinteger(V);

if isVolumeInt
   intClass = class(V);
   V = im2double(V);
end

if isColorIm
   I = squeeze(sum(V, dim));
else
   I = squeeze(sum(V, dim));
end

if isVolumeInt
   I = csmu.double2im(I / max(I, [], 'all'), intClass);
end

end


function unittest
parentFuncName = strcat('csmu.', mfilename);
fcnName = strcat(parentFuncName, '>unittest');
L = csmu.Logger(fcnName);
printtest = @(s) L.info('\t%s ...', s);
printpass = @() L.info('\t\tpassed.');
L.info('Unit tests for %s:\n', parentFuncName);

printtest('Simple Test');
V = zeros(3, 3, 3);
V(1, 1, 3) = 1;
sumim = csmu.(mfilename)(V);
assert(all(sumim(:) == [1 0 0 0 0 0 0 0 0]'));
printpass();

printtest('Color Test');
V = zeros(3, 3, 3, 3);
V(1, 1, 3, 2) = 1;
sumim = csmu.(mfilename)(V);
assert(sumim(1, 1, 1) == 0);
assert(sumim(1, 1, 2) == 1);
printpass();

printtest('Color Weight Test')
V = zeros(3, 3, 3, 3);
V(1, 1, 3, 1) = 1;
V(1, 1, 2, 2) = 0.9;
colorwt = [0.5 1 1];
sumim = csmu.(mfilename)(V, 'ColorWeight', colorwt);
assert(sumim(1, 1, 1) == 1);
assert(sumim(1, 1, 2) == 0.9);
printpass();
end