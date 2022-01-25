function binEdges = imhistLocs2Edges(binLocs)

n = length(binLocs);
A = max(binLocs, [], 'all');
B = min(binLocs, [], 'all');
p = 1:n;
leftEdges = (A * (p - 1.5) / (n - 1)) - B;
finalEdge = (A * (p(end) - 0.5) / (n - 1)) - B;

binEdges = [leftEdges(:); finalEdge];
binEdges([1, end]) = [B, A];
end