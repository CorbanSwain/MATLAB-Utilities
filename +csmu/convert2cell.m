function cellVal = convert2cell(val)
% convert2cell returns the value if it is a cell otherwise convert.
L = csmu.Logger('convert2cell');
L.warn('csmu.convert2cell is deprecated, use csmu.tocell instead.');
if iscell(val)
    cellVal = val;
else
    cellVal{1} = val;
end
end