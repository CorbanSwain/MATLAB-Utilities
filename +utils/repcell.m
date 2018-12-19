function outCell = repcell(c, varargin)
sz = size(c);
multiplier = cell2mat(varargin);
l1 = length(sz) ;
l2 = length(multiplier);
l = max(l1, l2);
lenDiff = l1 - l2;
if lenDiff > 0
   multiplier = [multiplier, ones(1, lenDiff)];
else
   sz = [sz, ones(1, -lenDiff)];
end
newSz = sz .* multiplier;
outCell = cell(newSz);

baseSel = arrayfun(@(s) 1:s, sz, 'UniformOutput', false);
repunitSel = baseSel;

for i = 1:l
   if i == 1
      repunit = c;
   else
      repunitSel{i - 1} = 1:newSz(i - 1);
      repunit = outCell(repunitSel{:});
   end
   
   for iMultVal = 1:multiplier(i)
      thisSel = repunitSel;
      thisSel{i} = thisSel{i} + ((iMultVal - 1) * sz(i));
      outCell(thisSel{:}) = repunit;
   end
end
end