function out = loopIndexCell(c, i)
out = c{utils.mod1(i, length(c))};
