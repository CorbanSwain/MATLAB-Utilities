function isvalid = member(x, list)
for iVal = 1:length(list)
   if isequal(list{iVal}, x)
      isvalid = true;
      return
   end
end
isvalid = false;

