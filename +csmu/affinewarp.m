%AFFINEWARP Apply an affine transform to a 3D array.   
%This function uses an inverse transform algorithm to assign each point in
%the output array to a point in the input array.
%
%   Syntax:
%   -------
%   B = AFFINEWARP(A, RA, tform) transforms the `A` according to `tform` and 
%   returns the result as `B`.
%
%   B = AFFINEWARP(..., 'OutputView', RB) ensures the ouput is limited to the
%   space defined by `RB`.
%
%   [B, RB] = AFFINEWARP(...) returns the spacial reference which the output
%   covers.
%
%   [B, RB, P, filt] = AFFINEWARP(...) returns `P` and `filt` which can be used
%   to specify the operation performed by AFFINEWARP as a series of index
%   assignments such that `B = zeros(RB.ImageSize); B(filt) = A(P)` repeats 
%   the transformation. These outputs can be useful for speeding up repeated
%   transformations on different input arrays of the same size.
%
%   AFFINEWARP() called with no arguments will perform a unit test suite on the
%   affinewarp function, and print profiling and debugging results to the 
%   console.
%
%   Inputs:
%   -------
%      A - a numeric array to be transformed. 
%          * `ndims(A)` must equal 3.
%
%      RA - a spatial reference object which specifies the extents of A in 
%           world coordinates.
%           * type: imfef3d, csmu.ImageRef
%           * `RA.ImageSize` must equal `size(A)`
%
%      tform - a transform object which specifies how to transform A.
%              * type: affine3d, csmu.Transform
%
%      parameter/value pairs:
%         'OutputView' - a spatial reference object which specifies the extents 
%                        of the output view in world coordinates. This will 
%                        change how the transformed output is cropped.
%                        * type: imref3d, csmu.ImageRef
%
%   Outputs:
%   --------
%      B - the transformation of the input array
%      
%      RB - the spatial ref of the output array referenced to the input
%           coordinate system supplied by RA. If the 'OutputView'
%           parameter/value pair argument is specified, RB will be the same as
%           that value.
%           * type: imref3d, csmu.ImageRef
%
%      P - the list of indices in the input volume to be assiged to a
%          subset of the output volume. `P` and `filt` are provided such that 
%          `B(filt) = A(P)` is equivalent to performing the transform.
%
%      filt - the points in the output space `B` which should be set to 
%             points from the input `A` specified as a binary array. `P` 
%             and `filt` are provided such that  `B(filt) = A(P)` is 
%             equivalent to performing the transform.
%
%   See also AFFINE3D, IMREF3D, CSMU.TRANSFORM, CSMU.IMAGEREF, IMWARP, 
%   IMREGTFORM, GEOMETRICTRANSFORM3D.
  
function [varargout] = affinewarp(A, RA, tform, varargin)
%% Input Handling
L = csmu.Logger('csmu.affinewarp');
if nargin == 0
   unittest;
   return
end
RB = parseInputs(varargin);
L.assert(all(size(A) == RA.ImageSize));
L.assert(any(nargout == [0 1 2 4]));
%% Setup
L.debug('Setting up transform matrices');
if isfloat(A)
   VARCLASS = class(A);
else
   VARCLASS = 'double';
end
L.debug('VARCLASS = %s', VARCLASS);

I = eye(4);
shiftsel = {4, 1:3};
scalesel = {[1 6 11]};

% 1 - shift to zero
T1 = I;
T1(shiftsel{:}) = -1 * ones(1, 3);

% 2 - scale to world
T2 = I;
T2(scalesel{:}) = [RA.PixelExtentInWorldX, ...
   RA.PixelExtentInWorldY, ...
   RA.PixelExtentInWorldZ];

% 3 - shift to world lim
T3 = I;
T3(shiftsel{:}) = [RA.XWorldLimits(1), ...
   RA.YWorldLimits(1), ...
   RA.ZWorldLimits(1)];

% 4 - transform
T4 = tform.T;

if isempty(RB)
   testP = corners(RA.ImageSize);
   testP = [testP, ones(8, 1)];
   testP = testP * (T1 * T2 * T3 * T4);
   testP(:, 4) = [];
   testLims = [min(testP); max(testP)];
   testSz = ceil(diff(testLims) + 1);
   RB = imref3d(testSz([2 1 3]), ...
      [0 testSz(1)] + testLims(1, 1), ...
      [0 testSz(2)] + testLims(1, 2), ...
      [0 testSz(3)] + testLims(1, 3));
end

% 5 - shift to zero
T5 = I;
T5(shiftsel{:}) = -1 .* [RB.XWorldLimits(1), ...
   RB.YWorldLimits(1), ...
   RB.ZWorldLimits(1)];

% 6 - scale to units
T6 = I;
T6(scalesel{:}) = 1 ./ [RB.PixelExtentInWorldX, ...
   RB.PixelExtentInWorldY, ...
   RB.PixelExtentInWorldZ];

% 7 - shift to one
T7 = I;
T7(shiftsel{:}) = ones(1, 3);

% 8 - convert from subscript to an index into A
T8 = [RA.ImageSize(1); 1; prod(RA.ImageSize(1:2))];
T8Shift = 1 - sum(T8);
T8 = [T8; T8Shift];

L.debug('Input image size [%s]', num2str(RA.ImageSize))
L.debug('Output image size [%s]', num2str(RB.ImageSize))

%% Performing Warp Computation
numelB = prod(RB.ImageSize);
minChunkSz = 1e8;
if numelB > minChunkSz
   L.debug('numelB (%.5e) over threshold (%.5e)', numelB, minChunkSz);
   [~, sv] = memory;
   avalailableMem = sv.PhysicalMemory.Available;
   L.debug('Avalible Memory: %.1f GB', avalailableMem / 1E9);
   heuristic = 10 * 32; % was 15
   chunkSz = avalailableMem / heuristic;
   threshChunkSz = chunkSz * 5;
   L.debug('Threshold chunk size = %.5e', threshChunkSz);
   doIter = numelB > threshChunkSz;
else
   L.debug('numelB (%.5e) NOT over threshold (%.5e)', numelB, ...
      minChunkSz);
   doIter = false;
end

T = affine3d(T1 * T2 * T3 * T4 * T5 * T6 * T7);
helperArgs = {RA, RB, T, T8, VARCLASS};
if doIter
   L.debug(['Volume is too large to warp in one-pass,', ...
      ' performing chunked computation']);
   pgSz = prod(RB.ImageSize(1:2));
   % round to multiple of the volumes pagesize to speed up gridvec
   chunkSz = round(chunkSz / pgSz) * pgSz;
   %chunkSz = 100 * pgSz;
   L.debug('ChunkSize = %d pages', chunkSz / pgSz);
   chunks = csmu.getchunks(chunkSz, numelB, 'greedy');
   nChunks = length(chunks);
   t1 = tic;
   filt = false(1, numelB);
   P = zeros(1, numelB);
   Psel = [0, 0];
   startIdx = 0;   
   for iChunk = 1:nChunks
      L.debug('Beginnging chunk %2d / %2d', iChunk, nChunks);
      tic;
      chunkSel = (1:chunks(iChunk)) + startIdx;
      [subP, subfilt] = awHelper(helperArgs{:}, chunkSel);
      L.debug('Placing chunk of filter');
      filt(chunkSel) = subfilt;
      L.debug('Placing chunk of A point selection');
      Psel = [Psel(2) + 1, Psel(2) + length(subP)];
      P(Psel(1):Psel(2)) = subP;
      startIdx = chunkSel(end);
      L.debug('\t... took %7.3f seconds', toc);
   end
   L.debug('Removing extra points in P.');
   P = P(1:Psel(2));
   t1 = toc(t1);
   L.debug('Warp Time = %.2f, SCORE = %2d', t1, round(t1 / numelB * 2e9));
else
   L.debug('Performing computation in one pass');
   t1 = tic;
   chunkSel = 1:prod(RB.ImageSize);
   [P, filt] = awHelper(helperArgs{:}, chunkSel);
   t1 = toc(t1);
   L.debug('Warp Time = %.2f, SCORE = %2d', t1, round(t1 / numelB * 2e9));
end

tic;
L.debug('Allocating output volume');
B = zeros(RB.ImageSize, VARCLASS);
L.debug('Placing points into output output space.');
B(filt) = A(P);
L.debug('Placing points took %.3f seconds', toc);

%% Place in Space
L.debug('Returning output');
switch nargout
   case 1
      varargout = {B};
   case 2
      varargout = {B, RB};
   case 4
      varargout = {B, RB, P, filt};
end
end

function [P, filt] = awHelper(RA, RB, T, T8, VARCLASS, chunkSel)
L = csmu.Logger('csmu.affinewarp>awHelper');

L.debug('Creating point vectors');
% TODO - time this with padarray
P = [gridvec(RB.ImageSize, 'ChunkSel', chunkSel, 'Class', VARCLASS), ...
   ones(length(chunkSel), 1, VARCLASS)];

%% Inverse Transform
L.debug('Performing inverse transformation');
P = round(P * T.invert.T);

%% Filter out Invalid Points
L.debug('Building filter');
filt = all(P >= 1, 2) & all(P <= [RA.ImageSize([2 1 3]), 1], 2);
L.debug('Filtering out invalid points');
P = P(filt, :);

L.debug('Converting to double then mat-multiplying to get indices');
P = double(P) * T8; % must convert to double because of indices > 1e9
end

function RB = parseInputs(args)
p = inputParser;
p.addParameter('OutputView', []);
p.parse(args{:});
RB = p.Results.OutputView;
end

function P = corners(sz, varargin)
% locations of the corners of a volume with size sz
p = inputParser;
p.addOptional('onlyAxes', [], @(x) strcmpi(x, 'axes'));
p.parse(varargin{:});
doOnlyAxes = ~isempty(p.Results.onlyAxes);
if doOnlyAxes
   P = [1 1 1; sz(2) 1 1; 1 sz(1) 1; 1 1 sz(3)];
else
   P = combvec([1 sz(2)], [1 sz(1)], [1, sz(3)]);
   P = P';
end
end

function V = makevecs(a, b, sz)
V = {linspace(a(1), b(1), sz(2)), ...
   linspace(a(2), b(2), sz(1))', ...
   reshape(linspace(a(3), b(3), sz(3)), 1, 1, [])};
end

function P = vecs2points(v)
sz = [num2cell(cellfun(@(x) length(x), v([2 1 3]))), {1}];
P = [reshape(repmat(v{1}, sz{[1 4 3]}), [], 1), ... % sz{4} represents 1
   reshape(repmat(v{2}, sz{[4 2 3]}), [], 1), ...
   reshape(repmat(v{3}, sz{[1 2 4]}), [], 1)];
end

function P = gridvec(sz, varargin)
L = csmu.Logger('csmu.affinewarp>gridvec');
L.assert(isvector(sz), 'sz must be a vector.');
p = inputParser;
p.addParameter('ChunkSel', [], @(x) isvector(x) & all(x > 0));
p.addParameter('Class', 'double', @(x) ischar(x) & isvector(x));
p.parse(varargin{:});
chunkSel = p.Results.ChunkSel;
VARCLASS = p.Results.Class;

if isempty(chunkSel)
   L.debug('Calulating grid vectors for all points');
   %%% hardcoding for speed
   a = ones(1, 3, VARCLASS);
   b = cast(sz([2 1 3]), VARCLASS);
   P = vecs2points(makevecs(a, b, sz));
   
   %%% more elegant method
   % ne = prod(sz);
   % nd = length(sz);
   % P = cell(1, nd);
   % for i = 1:nd
   %     P{i} = colon(cast(1, VARCLASS), cast(sz(i), VARCLASS));
   % end
   % [P{[2 1 3]}] = ndgrid(P{:});
   % P = reshape(cat(nd + 1, P{:}), [], nd);
else
   L.debug('Calculating grid vectors for a chunk of points.');
   Plim = cell(3, 1);
   [Plim{:}] = ind2sub(sz, chunkSel([1, end]));
   Plim = cell2mat(Plim);
   Plim = cast(Plim, VARCLASS);
   Plim = mat2cell(Plim, 3, [1 1]);
   [a, b] = Plim{:};
   a(1:2) = 1;
   b(1:2) = sz(1:2);
   coordOrder = [2 1 3];
   P = vecs2points(makevecs(a(coordOrder), b(coordOrder), ...
      [sz(1:2), b(3) - a(3) + 1]));
   if ~all(Plim{1}(1:2)' == 1 & Plim{2}(1:2)' == sz(1:2))
      startPage = double(a(3));
      P = P(chunkSel - ((startPage - 1) * prod(sz(1:2))), :);
   end
end
end

function unittest
L = csmu.Logger('csmu.affinewarp>utest');

levelOld = L.windowLevel;
cleanup = onCleanup(@() L.globalWindowLevel(levelOld));
L.globalWindowLevel(csmu.LogLevel.DEBUG);
L.logline(1);
L.info('Performing unit tests.');

%% Gridvec Test
a = tic;
sz = [10 11 12];
sel = (105:315) + 400;
P1 = gridvec(sz, 'Class', 'single');
P2 = gridvec(sz, 'ChunkSel', sel, 'Class', 'single');
L.assert(all(all(P1(sel, :) == P2)));
L.info('Gridvec test passed in %f seconds.\n.', toc(a));

%% Case 1
a = tic;
sz = [10 11 12];
A = rand(sz);
RA = csmu.centerImRef(sz);
tform = affine3d;
B = csmu.affinewarp(A, RA, tform);
L.assert(all(A(:) == B(:)));
L.info('Identity transform test passed in %f seconds.\n.', toc(a));

%% Case 2
PSF = getPsf;

indexMaps = cell(2, 2);
outputRefs = cell(1, 2);
outputs = cell(1, 2);
imageClass = 'single';

imSz = round([1200 1000 1000] * 1);
RA = csmu.centerImRef(imSz);
A = cell(1, 2);
A = csmu.cellmap(@(~) rand(imSz, imageClass), A);

tforms = csmu.Transform(1, 2);
[tforms.Rotation] = deal([88.5, 0, 2]);
[tforms.Translation] = deal([10, 3, 4]);
tforms(2).DoReverse = true;

L.info('Performing simulation on volume of size [%s].\n.', num2str(imSz));

psfTime = zeros(1, 2);

t1 = tic;
for i = 1:2      
   tP = tic;
   [~] = PSF.H + 1;
   [~] = PSF.Ht + 1;
   psfTime(i) = toc(tP);
   
   t2 = tic;
   [outputs{i}, outputRefs{i}, indexMaps{i, :}] = ...
      csmu.affinewarp(A{i}, RA, tforms(i));   
   L.info('Transform %d took %.2f min', i, toc(t2) / 60);
end
t1 = toc(t1);
L.info('Multi-large volume transform test passed in %.2f min.', ...
   (t1 - sum(psfTime)) / 60);
L.info('\t(total time; %.2f min; psfTime = [%s] s)\n.', t1 / 60, ...
   num2str(psfTime));

t1 = tic;
outputs = csmu.cellmap(@(r) zeros(r.ImageSize, imageClass), outputRefs);
for i = 1:2
   tP = tic;
   [~] = PSF.H + 1;
   [~] = PSF.Ht + 1;
   psfTime(i) = toc(tP);
   
   t2 = tic;   
   [P, filt] = indexMaps{i, :};
   outputs{i}(filt) = A{i}(P);
   L.info('Repeat transform %d took %.2f min.', i, toc(t2) / 60);
end
t1 = toc(t1);
L.info('Multi-repeat transforms took %.2f min.', (t1 - sum(psfTime)) / 60);
L.info('\t(total time; %.2f min; psfTime = [%s] s)\n.', t1 / 60, ...
   num2str(psfTime));
L.info('Done.');
L.logline(-1);
end
