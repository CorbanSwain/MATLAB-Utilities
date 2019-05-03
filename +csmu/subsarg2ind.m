function indexes = subsarg2ind(objSize, subs)
if strcmpi(subs, ':')
   subs = {1:prod(objSize)};
end
for iSub = 1:length(subs)
   if strcmpi(subs{iSub}, ':')
      subs{iSub} = 1:objSize(iSub);
   end
end
outSize = csmu.cellmap(@(v) length(v), subs);
indexes = cell(1, length(outSize));
[indexes{:}] = ndgrid(subs{:});
indexes = sub2ind(objSize, indexes{:});
end