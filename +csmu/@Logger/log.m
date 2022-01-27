function log(self, level, lineNum, varargin)

doWindowLog = self.windowLevel <= level;
doLog = self.level <= level;
% if doing no loggong, just end here
if ~(doWindowLog || doLog)
   return
end

name = self.truncatedScriptName;
if ~isempty(lineNum)
   name = sprintf('%s (% 4d)', name, lineNum);
else
   if self.doAutoLineNumber
      name = sprintf('%s (----)', name);
   end
end

if isstruct(varargin{1})
   if length(varargin) > 1
      structName = sprintf(varargin{2:end});
   else
      structName = 'struct';
   end
   message = struct2str(varargin{1}, structName);
else
   message = sprintf(varargin{:});
end

if strlength(message) == 0
   return
   % message = '[empty line]';
end

msgLines = splitlines(message);
nLines = length(msgLines);
if nLines > 1
   for iLine = 1:nLines
      self.log(level, lineNum, char(msgLines{iLine}))
   end
   return
end

% If necessary write to command window
if self.doIndent && self.indentLevel > 0
   makeLogstring = @() sprintf(['%s', self.format], ...
      repmat('|  ', 1, self.indentLevel), name, message);
else
   makeLogstring = @() sprintf(self.format, name, message);
end

logstring = char();
if doWindowLog
   outputId = (level >= csmu.LogLevel.ERROR) + 1;
   logstring = makeLogstring();
   fprintf(outputId, '%s \n', logstring);
end

if doLog
   % Append new log to log file
   if isempty(logstring)
      logstring = makeLogstring();
   end

   try
      temp_a = [self.stampFormat, '%s \n'];
      temp_b = datestr(now, self.datetimeFormat);
      temp_c = sprintf(self.idFormat, self.id);

      fid = fopen(self.path, 'a');
      cleanup = onCleanup(@() fclose(fid));
      fprintf(fid, temp_a, temp_b, level, temp_c, logstring);
   catch ME_1
      disp(ME_1);
   end
end
end

function str = struct2str(varargin)
str = csmu.struct2str(varargin{:});
str = cellfun(@(x) strrep(x, '\', '\\\\'), str, 'UniformOutput', false);
str = join(str, ['\n', repmat(' ', 1, 2)]);
str = str{:};
str = sprintf(str);
end