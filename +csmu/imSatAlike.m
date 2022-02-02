function satIm = imSatAlike(im, refIm)
refMax = max(refIm, [], 'all');
refNumel = numel(refIm);
prcMax = 100 * sum(refIm < refMax, 'all') / refNumel;

satVal = prctile(im, prcMax, 'all');
satIm = csmu.bound(im, [], satVal);
end