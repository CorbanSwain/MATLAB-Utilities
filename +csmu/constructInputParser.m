function outputInputParser = constructInputParser(parserSpec, varargin)
ip = inputParser();
fcnName = strcat('csmu.', mfilename);
ip.FunctionName = fcnName;
ip.addParameter('Name', '', @csmu.validators.scalarStringLike);
ip.addParameter('Args', [], @iscell);
ip.addParameter('DoKeepUnmatched', false);
ip.addParameter(...
   'DoWithholdReqParamDefaultArg', ...
   false, ...
   @csmu.validators.logicalScalar);
ip.parse(varargin{:});
inputs = ip.Results;
ip = ip.Results;
functionName = ip.Name;
inputArgs = ip.Args;
doKeepUnmatched = ip.DoKeepUnmatched;

L = csmu.Logger(fcnName);
elL.warn('This function is deprecated; use `csmu.InputParser.fromSpec(...)`.');

outputInputParser = csmu.InputParser.fromSpec(...
   parserSpec, ...
   'DoWithholdReqParamDefaultArg', inputs.DoWithholdReqParamDefaultArg);
outputInputParser.FunctionName = functionName;
outputInputParser.KeepUnmatched = doKeepUnmatched;

if iscell(inputArgs)
   try
      outputInputParser.parse(inputArgs{:});
   catch ME
      ME.throwAsCaller();
   end
end

% requiredFlags = {'r', 'required', 'addrequired'};
% optionalFlags = {'o', 'optional', 'addoptional'};
% parameterFlags = {'p', 'param', 'parameter', 'addparameter'};
% reqParamFlags = {'rp', 'reqparam', 'addrequiredparameter'};
% 
% reqParams = {};
% 
% outputInputParser = inputParser();
% outputInputParser.FunctionName = functionName;
% outputInputParser.KeepUnmatched = doKeepUnmatched;
% 
% didWarn = false;
% 
% for iSpec = 1:length(parserSpec)
%    spec = parserSpec{iSpec};
%    inputTypeFlag = lower(spec{1});
%    args = spec(2:end);
%    
%    switch inputTypeFlag
%       case requiredFlags
%          validatorIdx = 2;
%       case [optionalFlags, parameterFlags]
%          validatorIdx = 3;
%       case reqParamFlags
%          validatorIdx = 3;         
%          reqParams = [reqParams, args(1)];
%          if inputs.DoWithholdReqParamDefaultArg
%             args = [args(1), {[]}, args(2:end)];
%          elseif ~didWarn
%             didWarn = true;
%             L = csmu.Logger(fcnName);
%             L.warn(strcat('Deprecated behavior. Remove default arguments', ...
%                ' from all required params (rp) in parser spec and set the', ...
%                ' `DoWithholdReqParamDefaultArg` parameter to true when', ...
%                ' calling `constructInputParser(...)`.'));
%          end
%    end
%    if length(args) == validatorIdx
%       if csmu.validators.stringLike(args{validatorIdx})
%          args{validatorIdx} = @(x) csmu.validators.(args{validatorIdx})(x);
%       elseif iscell(args{validatorIdx})
%          args{validatorIdx} = ...
%             @(x) csmu.validators.member(x, args{validatorIdx});
%       end
%    end
%    
%    switch inputTypeFlag
%       case requiredFlags
%          outputInputParser.addRequired(args{:});         
%       case optionalFlags
%          outputInputParser.addOptional(args{:});         
%       case [parameterFlags, reqParamFlags]
%          outputInputParser.addParameter(args{:});
%    end
% end
% 
% if iscell(inputArgs)
%    if ~exist('L', 'var') 
%       L = csmu.Logger(fcnName);
%    end
%    
%    try
%       outputInputParser.parse(inputArgs{:});
%    catch ME
%       L.logException(csmu.LogLevel.ERROR, ME);
%       ME.throwAsCaller();
%    end
%    
%    if ~isempty(reqParams)
%       isMissingReqParam = contains(outputInputParser.UsingDefaults, reqParams);
%       if any(isMissingReqParam)
%          errId = 'csmu:InputParser:MissingParams';
%          errMsg = sprintf(strcat('The following required parameters were', ...
%             ' not provided: ''%s''.'), csmu.cell2csl(join(...
%             outputInputParser.UsingDefaults(isMissingReqParam), ''', ''')));
%          ME = MException(errId, errMsg);
%          L.logException(csmu.LogLevel.ERROR, ME);
%          ME.throwAsCaller();
%       end
%    end
% end
end