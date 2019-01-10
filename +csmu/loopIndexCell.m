function out = loopIndexCell(c, i)
out = c{csmu.mod1(i, length(c))};
