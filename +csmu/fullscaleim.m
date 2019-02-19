function I = fullscaleim(I)
if ~isfloat(I)
   I = im2double(I);
end
minI = min(I(:));
while ~gather(isscalar(minI))
   minI = min(minI);
end
I = I - minI;

maxI = max(I(:));
while ~gather(isscalar(maxI))
   maxI = max(maxI);
end
I = I / maxI;
