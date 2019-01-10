function mustBeUnsignedIntClassName(x)
validTypes = csmu.cellmap(@(i) sprintf('uint%d', i), num2cell([8 16 32 64]));
if ~any(strcmpi(x, validTypes))
   error('Value must be the name of a valid unsigned integer class.');
end
end