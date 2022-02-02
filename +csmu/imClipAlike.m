function clippedIm = imClipAlike(im, refIm)
refRange = csmu.range(refIm);
refNumel = numel(refIm);
prcMin = 100 * sum(refIm <= refRange(1), 'all') / refNumel;
prcMax = 100 * sum(refIm < refRange(2), 'all') / refNumel;

clipRange = prctile(im, [prcMin, prcMax], 'all');
clippedIm = csmu.bound(im, clipRange(1), clipRange(2));
end