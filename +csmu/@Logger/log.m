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

try
   if isstruct(varargin{1})
      if length(varargin) > 1
         [structName, sprintfErr] = sprintf(varargin{2:end});
         sprintfFormat = varargin{2};
      else
         structName = 'struct';
         sprintfErr = [];
      end
      message = struct2str(varargin{1}, structName);
   else
      [message, sprintfErr] = sprintf(varargin{:});
      sprintfFormat = varargin{1};
   end

catch ME
   newME = MException('csmuLogger:messagePreparationError', ...
      'Log message formatting failed.');
   newME = newME.addCause(ME);
   h_logger = csmu.Logger(strcat('csmu.', mfilename(), '.log'));
   h_logger.logException(self.ERROR, newME);
   newME.throw();
end

if strlength(message) == 0
   return
   % message = '[empty line]';
end

if ~(isempty(sprintfErr) || isequal(message, sprintfFormat))
   h_logger = csmu.Logger(strcat('csmu.', mfilename(), '.log'));
   h_logger.warn(['Issue encountered with formatting of ' ...
      'the log message. %s\n' ...
      '...from format: ''%s'''], ...
      sprintfErr, sprintfFormat);
end

msgLines = splitlines(message);
nLines = length(msgLines);
if nLines > 1
   for iLine = 1:nLines
      logHelper(self, level, name, char(msgLines{iLine}), doLog, doWindowLog);
   end
else
   logHelper(self, level, name, message, doLog, doWindowLog);
end
end

function logHelper(self, level, name, message, doLog, doWindowLog)
% If necessary write to command window
if self.doIndent && self.indentLevel > 0
   makeLogstring = @() sprintf(['%s', self.format], ...
      repmat('|  ', 1, self.indentLevel), name, message);
else
   makeLogstring = @() sprintf(self.format, name, message);
end

logstring = char();
if doWindowLog
   outputId = (level >= csmu.LogLevel.WARN) + 1;
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
      clear('cleanup');
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