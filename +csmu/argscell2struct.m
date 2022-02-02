function S = argscell2struct(c)
c = c(:)';
S = cell2struct(c(2:2:end), c(1:2:end), 2);
end