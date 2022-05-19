function S = argscell2struct(c)
c = c(:)';
argNames = cellfun(@char, c(1:2:end), 'UniformOutput', false);
argValues = c(2:2:end);
S = cell2struct(argValues, argNames, 2);
end