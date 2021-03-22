function isvalid = member(x, list)
try
   isvalid = ismember(x, list);
catch ME
   switch ME.identifier
      case 'MATLAB:ISMEMBER:InputClass'
         isvalid = false;
      otherwise
         ME.rethrow();
   end
end
end

