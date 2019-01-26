function out = loopIndex(arr, idx)
% FIXME - allow for dimension specification
out = arr(csmu.mod1(idx, numel(arr)));
end