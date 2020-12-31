function logException(self, level, ME)
 report = ME.getReport;
 % report = strrep(report, self.scriptName, '`**NAME**`');
 report = strrep(report, '\', '\\');
if strlength(ME.identifier)
   msg = sprintf('vv Error ID: %s vv\\n%s', ME.identifier, ...
      stripFormat(report));
else
   msg = stripFormat(report);
end

if self.doAutoLineNumber
   try
      lineNum = ME.stack(1).line;
   catch
      lineNum = [];
   end
else
   lineNum = [];
end
self.log(level, lineNum, msg);
end

function s = stripFormat(s)
s = splitlines(s);
s = join(s, '\n');
[~, s] = regexp(s, '<a\s*href=".*?".*?>|<\/a>', 'match', 'split');
s = join(s{1}, '');
s = s{:};
end
