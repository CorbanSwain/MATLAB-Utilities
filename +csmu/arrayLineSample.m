function [varargout] = arrayLineSample(A, point, varargin)
L = csmu.Logger('csmu.arrayLineSample');

if ~nargin
   L.info('Beginning unit tests.');
   unittest;
   return;
end

ip = inputParser;
ip.addParameter('ImageRef', csmu.ImageRef(A));
ip.parse(varargin{:});
imRef = ip.Results.ImageRef;

nDim = length(point);
imRef = csmu.ImageRef(imRef);
tform = csmu.imref2translation(imRef);
tform.Translation = tform.Translation - 1;
tform.DoReverse = true;
imageCoordPoint = tform.warpPoints(point);

sz = size(A);
assert(all(imageCoordPoint >= 0.5), 'Point outside of image bounds');
assert(all(imageCoordPoint <= (0.5 + sz([2 1 3]))), ...
   'Point outside of image bounds');

varargout = cell(1, nDim);
idxArgs = arrayfun(@(n) 1:size(A, n), 1:nDim, 'UniformOutput', false);
floorPoint = floor(imageCoordPoint);
ceilPoint = ceil(imageCoordPoint);
nOtherDim = nDim - 1;
if nDim == 2
   shape = [2, 1];
else
   shape = ones(1, nDim - 1) * 2;
end
shapeArgs = csmu.cellmap(@(i) 1:shape(i), num2cell(1:max(2, nOtherDim)));
for iDim = 1:nDim
   if iDim == 2
      dimIdx = 1;
   elseif iDim == 1
      dimIdx = 2;
   else
      dimIdx = iDim;
   end     
   otherDim = 1:nDim;
   otherDim(iDim) = [];
   vectors = cell(shape);
   subs = cell(1, nOtherDim);
   for iVec = 1:numel(vectors)
      [subs{:}] = ind2sub(shape, iVec);
      vecIdxArgs = idxArgs;
      for j = 1:nOtherDim         
         iOtherDim = otherDim(j);
         if iOtherDim == 2
            otherDimIdx = 1;
         elseif iOtherDim == 1
            otherDimIdx = 2;
         else
            otherDimIdx = iOtherDim;
         end
         if subs{j} == 1
            vecIdxArgs{iOtherDim} = floorPoint(otherDimIdx);
         else
            vecIdxArgs{iOtherDim} = ceilPoint(otherDimIdx);
         end
      end
      try
         vectors{subs{:}} = double(A(vecIdxArgs{:}));
         vectors{subs{:}} = vectors{subs{:}}(:);
      catch ME
         switch ME.identifier
            case 'MATLAB:badsubscript'
               vectors{subs{:}} = zeros(sz(iDim), 1);
            otherwise
               ME.rethrow;
         end
      end
   end
      
   weights = ones(shape);   
   for j = 1:nOtherDim
      newWeights = ones(shape);
      iOtherDim = otherDim(j);
      
      lowShapeArgs = shapeArgs;
      highShapeArgs = shapeArgs;
      lowShapeArgs{j} = 1;
      highShapeArgs{j} = 2;
      
      if iOtherDim == 2
         otherDimIdx = 1;
      elseif iOtherDim == 1
         otherDimIdx = 2;
      else
         otherDimIdx = iOtherDim;
      end
      
      val = imageCoordPoint(otherDimIdx);
      low = floorPoint(otherDimIdx);
      high = ceilPoint(otherDimIdx);
      if low < 0.5
         highPct = 1;
         lowPct = 0;
      elseif high > (sz(iOtherDim) + 0.5)
         highPct = 0;
         lowPct = 1;
      else
         highPct = val - low;
         lowPct = 1 - highPct;
      end
      newWeights(lowShapeArgs{:}) = lowPct;
      newWeights(highShapeArgs{:}) = highPct;
      weights = weights .* newWeights;
   end
   varargout{dimIdx} = sum(cat(2, vectors{:}) .* weights(:)', 2);
end
end

function unittest
L = csmu.Logger('csmu.arrayLineSample>unittest');
L.logline;
I = ones(5, 6, 7);
I = padarray(I, [1 0 1], 0);
[xl, yl, zl] = csmu.arrayLineSample(I, [0.5, 0.5, 8.9])
L.info('Test 1 complete');
L.logline;

ref = csmu.ImageRef(I);
ref.zeroCenter;
L.info(struct(ref), 'ImageRef')
[xl, yl, zl] = csmu.arrayLineSample(I, [0, 0, 0], 'ImageRef', ref)
end