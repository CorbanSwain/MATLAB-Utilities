function subI = subsample(I, window)
% L = csmu.Logger(['solver.' mfilename '>subSample']);
if nargin == 0
   unittest;
   return;
end
iSz = size(I);
numStrides = iSz ./ window;
assert(all(csmu.isint(numStrides)));
subI = zeros(numStrides, 'like', I);
selection = {1:window(1), 1:window(2)};
for i = 1:prod(numStrides)
   [iRow, iCol] = ind2sub(numStrides, i);
   rowStart = (iRow - 1) * window(1);
   colStart = (iCol - 1) * window(2);
   subI(i) = mean(I(selection{1} + rowStart, selection{2} + colStart), 'all'); 
end
end

function unittest
I = imread('cameraman.tif');
window = [16, 4];
subI = csmu.subsample(I, window);
subI = imresize(subI, size(I), 'nearest');
imshowpair(I, subI, 'falsecolor');
end