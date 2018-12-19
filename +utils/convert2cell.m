function cellVal = convert2cell(val)
% convert2cell returns the value if it is a cell otherwise convert.
L = utils.Logger('convert2cell');
L.warn('utils.convert2cell is deprecated, use utils.tocell instead.');
if iscell(val)
    cellVal = val;
else
    cellVal{1} = val;
end
end