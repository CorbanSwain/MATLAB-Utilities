function varargout = globCell(strs, formatStr)

formatStr = strrep(formatStr, '\', '\\');
for chr = {'.', '[', ']', '^', '(', ')', '|', '$', '+', '?', '{', '}'}
   formatStr = strrep(formatStr, chr{1}, ['\', chr{1}]);
end

formatStr = strcat('^', strrep(formatStr, '*', '.*'), '$');
mask = cellfun(@(x) ~isempty(x), regexp(strs, formatStr));

filtStrs = strs(mask);

nargoutchk(0, 2);
switch nargout
   case {0, 1}
      varargout = {filtStrs};
      
   case 2
      varargout = {filtStrs, find(mask)};
end
end