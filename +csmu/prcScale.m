function [I, varargout] = prcScale(I, prcPair)
% Rescales an image by clipping the top and bottom ends of the histogram

lowValue = prctile(I(:), prcPair(1) * 100);
highValue = prctile(I(:), prcPair(2) * 100);

I = (I - lowValue) / (highValue - lowValue);
I(I < 0) = 0;
I(I > 1) = 1;
