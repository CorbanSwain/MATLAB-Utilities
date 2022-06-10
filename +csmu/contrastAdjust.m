function I = contrastAdjust(I, contrast)

if contrast == 1
   return
end

maxVal = max(I, [], 'all');

% scale to 1
I = I / maxVal;

% center on 0, then scale by the contrast amount, then center on 0.5
I = (((contrast * ((2 * I) - 1)) + 1) / 2);

% scale back to original range
I = I * maxVal;
