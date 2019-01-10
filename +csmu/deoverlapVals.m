function [valDim, spreadDim, I] = deoverlapVals(X, varargin)
if nargin == 0
   unittest;
   return;
end

ip = inputParser;
ip.addParameter('MinBinSize', []);
ip.addParameter('MaxSpread', 1);
ip.parse(varargin{:});
minBinSize = ip.Results.MinBinSize;
maxSpread = ip.Results.MaxSpread;

dataRange = max(X) - min(X);
if isempty(minBinSize)
   N = 5;
else
   N = ceil(dataRange / minBinSize);
end
N = csmu.bound(N, 1, Inf);

XDiscrete = discretize(X, N);
numInBin = zeros(1, N);
for iBin = 1:N
   numInBin(iBin) = sum(XDiscrete == iBin);
end
maxInBin = max(numInBin);
if maxInBin < 3
   jitterVal = maxSpread / 2;
else
   jitterVal = maxSpread / (maxInBin - 1);
end

[valDim, spreadDim] = deal(zeros(size(X)));
lastIdx = 0;
I = zeros(size(X));
Iorig = 1:length(I);
for iBin = 1:N
   if numInBin(iBin) > 0
      binMembers = X(XDiscrete == iBin);
      [binMembers, sI] = sort(binMembers);
      [binMembers, foI] = csmu.funnelOrder(binMembers);      
      selection = (1:numInBin(iBin)) + lastIdx;
      lastIdx = selection(end);
      
      subI = Iorig(XDiscrete == iBin);
      subI = subI(sI);
      I(selection) = subI(foI);
      
      valDim(selection) = binMembers;
      spreadDim(selection) = csmu.zeroCenterVector(numInBin(iBin)) ...
         * jitterVal;
   end
end
end

function unittest
x = randn(1, 20);
[y, x2, I] = csmu.deoverlapVals(x, 'MinBinSize', 0.25);
assert(all((sort(x) - sort(y)) < 2 * eps(sort(y))));
assert(all((x(I) - y) < 2 * eps));
figure(1); clf;
plot(x2, y, 'g.', 'MarkerSize', 40);
for i = 1:length(x)
   t = text(x2(i), y(i), sprintf('%d', I(i)), 'HorizontalAlignment', ...
      'center');
end
disp(x(1:5));
end