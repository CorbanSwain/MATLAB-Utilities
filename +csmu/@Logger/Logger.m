classdef Logger < handle
   %LOGGER
   %
   % Author:
   %       Corban Swain <CorbanSwain@gmail.com>
   % Modified version of 'log4m' by Luke Winslow <lawinslow@gmail.com>:
   %       https://www.mathworks.com/matlabcentral/fileexchange/37701
   
   properties (Constant, Hidden = true)
      ALL   = csmu.LogLevel.ALL
      TRACE = csmu.LogLevel.TRACE
      DEBUG = csmu.LogLevel.DEBUG
      INFO  = csmu.LogLevel.INFO
      WARN  = csmu.LogLevel.WARN
      ERROR = csmu.LogLevel.ERROR
      FATAL = csmu.LogLevel.FATAL
      OFF   = csmu.LogLevel.OFF
      
      % Properties with instance counterpart
      DEFAULT_PATH {mustBeStringLike} = 'untitled_log.log'
      DEFAULT_FORMAT {mustBeStringLike} = '%s: %s'
      DEFAULT_STAMP_FORMAT {mustBeStringLike} = '[%s | %-7s | %s] '
      DEFAULT_DATETIME_FORMAT {mustBeDatestrFormat} = 'yymmdd-HH:MM:SS'
      DEFAULT_INDENT_MODE csmu.IndentMode = csmu.IndentMode.AUTO
      DEFAULT_WINDOW_LEVEL csmu.LogLevel = csmu.LogLevel.INFO
      DEFAULT_LEVEL csmu.LogLevel = csmu.LogLevel.ALL
      DEFAULT_MAX_SCRIPT_NAME_LENGTH ...
         {mustBeInteger, mustBeNonnegative} = 20
      DEFAULT_DO_AUTOLOG {mustBeBoolean} = true
      DEFAULT_DO_AUTO_LINE_NUMBER {mustBeBoolean} = true
      DEFAULT_ID = 0
      DEFAULT_ID_FORMAT = '%03d'
   end
   
   properties
      scriptName {mustBeStringLike} = ''
      
      % Properties with global counterpart
      path
      format
      stampFormat
      datetimeFormat
      indentMode
      windowLevel
      level
      maxScriptNameLength
      id
      idFormat
   end
   
   properties (Dependent, Access = protected)
      truncatedScriptName {mustBeStringLike}
      indentLevel {mustBeInteger, mustBeNonnegative}
      doIndent {mustBeBoolean}
      doAutolog {mustBeBoolean}
      doAutoLineNumber {mustBeBoolean}

   end
   
   methods (Static)
      testSpeed(N, path)
      
      function val = globalPath(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeWritablePath(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalFormat(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeStringLike(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalStampFormat(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeStringLike(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalDatetimeFormat(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeDatestrFormat(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalIndentMode(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeInstance(val, 'csmu.IndentMode');
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalWindowLevel(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               val = csmu.LogLevel(val);
               mustBeInstance(val, 'csmu.LogLevel');
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalLevel(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               val = csmu.LogLevel(val);
               mustBeInstance(val, 'csmu.LogLevel');
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalMaxScriptNameLength(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeInteger(val);
               mustBeNonnegative(val)
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalIndentLevel(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeInteger(val);
               mustBeNonnegative(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalDoAutolog(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeBoolean(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalDoAutoLineNumber(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeBoolean(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalId(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeInteger(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
      function val = globalIdFormat(val)
         persistent pVal;
         if nargin
            if strcmpi('clear', val) || isempty(val)
               pVal = [];
            else
               mustBeStringLike(val);
               pVal = val;
            end
         end
         val = pVal;
      end
      
   end
   
   
   methods
      %%% Constructor
      function self = Logger(name, path)
         switch nargin
            case 0
            case 1
               self.scriptName = name;
            case 2
               self.scriptName = name;
               self.path = path;
         end
         
         if self.indentMode == csmu.IndentMode.AUTO
            self.indent;
         end
         if self.doAutolog
            if self.doAutoLineNumber
               try
                  ME_1 = MException('', '');
                  ME_1.throwAsCaller;
               catch ME_2
                  try
                     lineNum = ME_2.stack(1).line;
                  catch
                     lineNum = [];
                  end
               end
            else
               lineNum = [];
            end
            self.log(self.TRACE, lineNum, ...
               'AUTOLOG: Beginning Logger for %s.', self.scriptName);
         end
      end
      
      %%% SETTERS
      function set.path(self, val)
         mustBeWritablePath(val);
         self.path = val;
      end
      
      function set.format(self, val)
         mustBeStringLike(val);
         self.format = val;
      end
      
      function set.stampFormat(self, val)
         mustBeStringLike(val);
         self.stampFormat = val;
      end
      
      function set.datetimeFormat(self, val)
         mustBeDatestrFormat(val);
         self.datetimeFormat = val;
      end
      
      function set.indentMode(self, val)
         mustBeInstance(val, 'csmu.IndentMode');
         self.indentMode = val;
      end
      
      function set.windowLevel(self, val)
         mustBeInstance(val, 'csmu.LogLevel');
         self.windowLevel = val;
      end
      
      function set.level(self, val)
         mustBeInstance(val, 'csmu.LogLevel');
         self.level = val;
      end
      
      function set.maxScriptNameLength(self, val)
         mustBeInteger(val);
         mustBeNonnegative(val);
         self.maxScriptNameLength = val;
      end
      
      function set.id(self, val)
         mustBeInteger(val);
         self.id = val;
      end
      
      function set.idFormat(self, val)
         mustBeStringLike(val);
         self.idFormat = val;
      end
      
      %%% Getters
      function val = get.path(self)
         val = self.path;
         if ~isempty(val), return; end
         
         val = self.globalPath;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_PATH;
      end
      
      function val = get.format(self)
         val = self.format;
         if ~isempty(val), return; end
         
         val = self.globalFormat;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_FORMAT;
      end
      
      function val = get.stampFormat(self)
         val = self.stampFormat;
         if ~isempty(val), return; end
         
         val = self.globalStampFormat;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_STAMP_FORMAT;
      end
      
      function val = get.datetimeFormat(self)
         val = self.datetimeFormat;
         if ~isempty(val), return; end
         
         val = self.globalDatetimeFormat;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_DATETIME_FORMAT;
      end
      
      function val = get.indentMode(self)
         val = self.indentMode;
         if ~isempty(val), return; end
         
         val = self.globalIndentMode;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_INDENT_MODE;
      end
      
      function val = get.windowLevel(self)
         val = self.windowLevel;
         if ~isempty(val), return; end
         
         val = self.globalWindowLevel;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_WINDOW_LEVEL;
      end
      
      function val = get.level(self)
         val = self.level;
         if ~isempty(val), return; end
         
         val = self.globalLevel;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_LEVEL;
      end
      
      function val = get.maxScriptNameLength(self)
         val = self.maxScriptNameLength;
         if ~isempty(val), return; end
         
         val = self.globalMaxScriptNameLength;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_MAX_SCRIPT_NAME_LENGTH;
      end
      
      function val = get.id(self)
         val = self.id;
         if ~isempty(val), return; end
         
         val = self.globalId;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_ID;
      end
      
      function val = get.idFormat(self)
         val = self.idFormat;
         if ~isempty(val), return; end
         
         val = self.globalIdFormat;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_ID_FORMAT;
      end
      
      %%% Dependent Getters
      function val = get.truncatedScriptName(self)
         val = self.scriptName;
         maxLen = self.maxScriptNameLength;
         if length(val) > maxLen
            ELLIPSIS = '...';
            ellipsisLen = length(ELLIPSIS);
            divLength = floor((maxLen - ellipsisLen) / 2);
            divLength = [divLength, maxLen - ellipsisLen - divLength];
            val = strcat(val(1:divLength(1)), ELLIPSIS, ...
               val((end - divLength(2) + 1):end));
         end
         val = sprintf('%-*s', maxLen, val);
      end
      
      function val = get.indentLevel(self)
         val = self.globalIndentLevel;
         if ~isempty(val), return; end
         
         val = 0;
      end
      
      function val = get.doIndent(self)
         val = self.indentMode ~= csmu.IndentMode.NONE;
      end
      
      function val = get.doAutolog(self)
         val = self.globalDoAutolog;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_DO_AUTOLOG;
      end
      
      function val = get.doAutoLineNumber(self)
         val = self.globalDoAutoLineNumber;
         if ~isempty(val), return; end
         
         val = self.DEFAULT_DO_AUTO_LINE_NUMBER;
      end
      
      %%% Indentation Functions
      function indent(self)
         il = self.globalIndentLevel;
         if isempty(il)
            self.globalIndentLevel(0);
         else
            self.globalIndentLevel(il + 1);
         end
      end
      
      function unindent(self)
         il = self.globalIndentLevel;
         if isempty(il)
         elseif il == 0
            self.globalIndentLevel('clear');
         else
            self.globalIndentLevel(il- 1);
         end
      end
      
      %%% Primary Logging Functions
      function trace(self, varargin)
         if self.doAutoLineNumber
            try
               ME_1 = MException('', '');
               ME_1.throwAsCaller;
            catch ME_2
               try
                  lineNum = ME_2.stack(1).line;
               catch
                  lineNum = [];
               end
            end
         else
            lineNum = [];
         end
         self.log(self.TRACE, lineNum, varargin{:});
      end
      
      function debug(self, varargin)
         if self.doAutoLineNumber
            try
               ME_1 = MException('', '');
               ME_1.throwAsCaller;
            catch ME_2
               try
                  lineNum = ME_2.stack(1).line;
               catch
                  lineNum = [];
               end
            end
         else
            lineNum = [];
         end
         self.log(self.DEBUG, lineNum, varargin{:});
      end
      
      function info(self, varargin)
         if self.doAutoLineNumber
            try
               ME_1 = MException('', '');
               ME_1.throwAsCaller;
            catch ME_2
               try
                  lineNum = ME_2.stack(1).line;
               catch
                  lineNum = [];
               end
            end
         else
            lineNum = [];
         end
         self.log(self.INFO, lineNum, varargin{:});
      end
      
      function warn(self, varargin)
         if self.doAutoLineNumber
            try
               ME_1 = MException('', '');
               ME_1.throwAsCaller;
            catch ME_2
               try
                  lineNum = ME_2.stack(1).line;
               catch
                  lineNum = [];
               end
            end
         else
            lineNum = [];
         end
         self.log(self.WARN, lineNum, varargin{:});
         warning(varargin{:});
      end
      
      function error(self, varargin)
         if isscalar(varargin) && isa(varargin{1}, 'MException')
            self.logException(self.ERROR, varargin{1});
            varargin{1}.rethrow();
         else
            try
               [errmsg, sprintfErr] = sprintf(varargin{:});               
            catch ME
               newME = MException('csmuLogger:messagePreparationError', ...
                  'Error message formatting failed.');
               newME = newME.addCause(ME);
               h_logger = csmu.Logger(strcat('csmu.', mfilename(), '.error'));
               h_logger.logException(self.ERROR, newME);
               newME.throw();
            end

            if ~isempty(sprintfErr)
               h_logger = csmu.Logger(strcat('csmu.', mfilename(), '.error'));
               h_logger.warn(['Issue encountered with formatting of ' ...
                  'the error message. %s\n' ...
                  '...from format: ''%s'''], ...
                  sprintfErr, varargin{1});
            end

            try
               error(errmsg);
            catch ME_1
               try
                  ME_1.throwAsCaller();
               catch ME_2
                  self.logException(self.ERROR, ME_2);
                  ME_2.rethrow();
               end
            end
         end
      end            
      
      function fatal(self, varargin)
         if isscalar(varargin) && isa(varargin{1}, 'MException')
            self.logException(self.FATAL, varargin{1});
            varargin{1}.rethrow;
         else
            try
               [errmsg, sprintfErr] = sprintf(varargin{:});
            catch ME
               newME = MException('csmuLogger:messagePreparationError', ...
                  'Fatal error message formatting failed.');
               newME = newME.addCause(ME);
               h_logger = csmu.Logger(strcat('csmu.', mfilename(), '.fatal'));
               h_logger.logException(self.ERROR, newME);
               newME.throw();
            end

            if ~isempty(sprintfErr)
               h_logger = csmu.Logger(strcat('csmu.', mfilename(), '.fatal'));
               h_logger.warn(['Issue encountered with formatting of ' ...
                  'the fatal error message. %s\n' ...
                  '...from format: ''%s'''], ...
                  sprintfErr, varargin{1});
            end

            try
               error(errmsg);
            catch ME_1
               try
                  ME_1.throwAsCaller;
               catch ME_2
                  self.logException(self.FATAL, ME_2);
                  ME_2.rethrow();
               end
            end
         end
      end
      
      function logline(self, varargin)
         self.logLine(varargin{:});
      end
      
      function logLine(self, lineType)
         if self.doAutoLineNumber
            try
               ME_1 = MException('', '');
               ME_1.throwAsCaller;
            catch ME_2
               try
                  if strcmpi(ME_2.stack(1).name, 'Logger.logline')
                     lineNum = ME_2.stack(2).line;
                  else
                     lineNum = ME_2.stack(1).line;
                  end
               catch
                  lineNum = [];
               end
            end
         else
            lineNum = [];
         end
         
         log = @(s) self.log(self.INFO, lineNum,  s);
         
         if nargin == 1
            lineType = 0;
         end
         
         switch lineType
            case 1
               log(['\\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/', ...
                  ' \\/ \\/ \\/ \\/ \\/ \\/ \\/ \\/']);
            case -1
               log(['/\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\', ...
                  ' /\\ /\\ /\\ /\\ /\\ /\\ /\\ /\\']);
            case 0
               log(['|||||||||||||||||||||||||||||||||||||||||||||||||||', ...
                  '|||||||||||']);
            otherwise
               log(repmat(char(string(lineType)), 1, 62));
         end
      end
      
      logException(self, level, lineNum, ME)
      
      assert(self, varargin)
      
   end % Public methods
   
   methods (Access = protected)
      
      %%% Destructor
      function delete(self)
         if isempty(self.indentMode) ...
               || isempty(self.doAutolog) ...
               || isempty(self.doAutoLineNumber)
            % if this is true, something went wrong, don't worry about
            % autologging
            return
         end
         
         if self.doAutolog
            if self.doAutoLineNumber
               try
                  ME_1 = MException('', '');
                  ME_1.throwAsCaller;
               catch ME_2
                  try
                     lineNum = ME_2.stack(1).line;
                  catch
                     lineNum = [];
                  end
               end
            else
               lineNum = [];
            end
            self.log(self.TRACE, lineNum, ...
               'AUTOLOG: Ending Logger for %s.', self.scriptName);
         end
         
         if self.indentMode == csmu.IndentMode.AUTO
            self.unindent;
         end
      end
      
      %%% Implementation of Logging
      log(self, level, lineNum, varargin)
      
   end
   
end

function mustBeBoolean(x)
if ~(isscalar(x) && islogical(x))
   error('Value must be a boolean (logical scalar).')
end
end

function mustBeInstance(x, cls)
if ~isa(x, cls)
   error('Value must be an instance of %s', cls)
end
end

function mustBeDatestrFormat(x)
try
   datestr(now, x);
catch ME
   ME.addCause(MException('ValidationError', ...
      'Value must be a valid date string format'));
   ME.rethrow;
end
end

function mustBeStringLike(x)
if ~((isstring(x) && isscalar(x)) || (ischar(x) && (isvector(x) ...
      || isempty(x))))
   error('Value must be string-like (string or character vector)');
end
end

function mustBeInteger(x)
if ~isinteger(x) && mod(x, 1) > eps(x)
   error('Value must be an integer; %f is not an integer.', x);
end
end

function mustBeWritablePath(x)
[fid, msg] = fopen(x, 'a');
if fid < 0
   error(['"%s" is not a writeable path: ' msg], x);
end
fclose(fid);
end
