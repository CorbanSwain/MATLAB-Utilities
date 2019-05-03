function I = fullscaleim(I)
if ~isfloat(I)
   I = im2double(I);
end
minI = gather(min(I, [], 'all'));
I = I - minI;

maxI = gather(max(I, [], 'all'));
I = I / maxI;
