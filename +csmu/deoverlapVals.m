function [newX, Y, newIdx] = deoverlapVals(X, varargin)
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


if iscell(X)
   didReceiveMatrix = false;
   numGroups = numel(X);
elseif isnumeric(X) && ismatrix(X)
   didReceiveMatrix = true;
   isRowVector = false;
   if isvector(X)
      numGroups = 1;
      if size(X, 1) == 1
         isRowVector = true;
      end
      X = {X(:)};
   elseif ismatrix(X)
      numGroups = size(X, 2);
      X = num2cell(X, 1);
   end
else
   error('Unexpected input type or shape');
end

[N, XDiscrete, numInBin, jitterVals, newX, Y, newIdx] ...
   = deal(cell(1, numGroups));
for iGroup = 1:numGroups
   XSlice = X{iGroup};
   dataRange = max(XSlice) - min(XSlice);
   if isempty(minBinSize)
      N{iGroup} = 5;
   else
      N{iGroup} = ceil(dataRange / minBinSize);
   end
   N{iGroup} = csmu.bound(N{iGroup}, 1, Inf);
   
   XDiscrete{iGroup} = discretize(XSlice, N{iGroup});
   numInBin{iGroup} = zeros(1, N{iGroup});
   for iBin = 1:N{iGroup}
      numInBin{iGroup}(iBin) = sum(XDiscrete{iGroup} == iBin);
   end
   maxInBin = max(numInBin{iGroup});
   if maxInBin < 3
      jitterVals{iGroup} = maxSpread / 2;
   else
      jitterVals{iGroup} = maxSpread / (maxInBin - 1);
   end
end

jitterVal = min(cat(2, jitterVals{:}));

for iGroup = 1:numGroups
   [newX{iGroup}, Y{iGroup}] = deal(zeros(size(X{iGroup})));
   lastIdx = 0;
   newIdx{iGroup} = zeros(size(X{iGroup}));
   oldIdx = 1:length(newIdx{iGroup});
   
   for iBin = 1:N{iGroup}
      if numInBin{iGroup}(iBin) > 0
         binMembers = X{iGroup}(XDiscrete{iGroup} == iBin);
         [binMembers, sI] = sort(binMembers);
         [binMembers, foI] = csmu.funnelOrder(binMembers);
         selection = (1:numInBin{iGroup}(iBin)) + lastIdx;
         lastIdx = selection(end);
         
         subI = oldIdx(XDiscrete{iGroup} == iBin);
         subI = subI(sI);
         newIdx{iGroup}(selection) = subI(foI);
         
         newX{iGroup}(selection) = binMembers;
         Y{iGroup}(selection) = ...
            csmu.zeroCenterVector(numInBin{iGroup}(iBin)) * jitterVal;
      end
   end
   [newIdx{iGroup}, sortId] = sort(newIdx{iGroup});
   newX{iGroup} = newX{iGroup}(sortId);
   Y{iGroup} = Y{iGroup}(sortId);
end

if didReceiveMatrix
   convertToMatrix = @(c) cat(2, c{:});
   [newX, Y, newIdx] = csmu.cell2csl(csmu.cellmap(convertToMatrix, ...
      {newX, Y, newIdx}));
   if isRowVector
         [newX, Y, newIdx] = csmu.cell2csl(csmu.cellmap(@transpose, ...
            {newX, Y, newIdx}));
   end
end
end

function unittest
nGroups = 5;
x = (randn(100, nGroups) ./ (0.5 + rand(1, nGroups) * 3)) + randn(1, nGroups);
[xNew, spread, I] = ...
   csmu.deoverlapVals(x, 'MinBinSize', 0.1, 'MaxSpread', 0.9);
assert(all((sort(x(:, 1)) - sort(xNew(:, 1))) < 2 * eps(sort(xNew(:, 1)))));
assert(all((x(I(:, 1), 1) - xNew(:, 1) < 2 * eps)));
fig = figure(1); clf; hold('on');
fig.Position = [20 20 1079 717];
plot(spread + (1:nGroups), xNew, 'g.', 'MarkerSize', 25);
for i = 1:length(x)
   t = text(spread(i) + 1, xNew(i), sprintf('%d', I(i)), ...
      'HorizontalAlignment', 'center', 'FontSize', 7, 'FontName', 'Input');
end
disp(x(1:5));
end