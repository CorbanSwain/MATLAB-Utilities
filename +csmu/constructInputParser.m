function outputInputParser = constructInputParser(parserSpec, varargin)
ip = inputParser();
ip.FunctionName = strcat('csmu.', mfilename);
ip.addParameter('Name', '', @csmu.validators.scalarStringLike);
ip.addParameter('Args', [], @iscell);
ip.addParameter('DoKeepUnmatched', false);
ip.parse(varargin{:});
ip = ip.Results;
functionName = ip.Name;
inputArgs = ip.Args;
doKeepUnmatched = ip.DoKeepUnmatched;

requiredFlags = {'r', 'required', 'addrequired'};
optionalFlags = {'o', 'optional', 'addoptional'};
parameterFlags = {'p', 'param', 'parameter', 'addparameter'};
reqParamFlags = {'rp', 'reqparam', 'addrequiredparameter'};

reqParams = {};

outputInputParser = inputParser();
outputInputParser.FunctionName = functionName;
outputInputParser.KeepUnmatched = doKeepUnmatched;
for iSpec = 1:length(parserSpec)
   spec = parserSpec{iSpec};
   inputTypeFlag = lower(spec{1});
   args = spec(2:end);
   
   switch inputTypeFlag
      case requiredFlags
         validatorIdx = 2;
      case [optionalFlags, parameterFlags]
         validatorIdx = 3;
      case reqParamFlags
         validatorIdx = 3;
         reqParams = [reqParams, args(1)];
   end
   if length(args) == validatorIdx
      if csmu.validators.stringLike(args{validatorIdx})
         args{validatorIdx} = @(x) csmu.validators.(args{validatorIdx})(x);
      elseif iscell(args{validatorIdx})
         args{validatorIdx} = ...
            @(x) csmu.validators.member(x, args{validatorIdx});
      end
   end
   
   switch inputTypeFlag
      case requiredFlags
         outputInputParser.addRequired(args{:});         
      case optionalFlags
         outputInputParser.addOptional(args{:});         
      case [parameterFlags, reqParamFlags]
         outputInputParser.addParameter(args{:});
   end
end

if iscell(inputArgs)
   try
      outputInputParser.parse(inputArgs{:});
   catch ME
      ME.throwAsCaller();
   end
   
   if ~isempty(reqParams)
      isMissingReqParam = contains(outputInputParser.UsingDefaults, reqParams);
      if any(isMissingReqParam)
         errId = 'csmu:InputParser:MissingParams';
         errMsg = sprintf(strcat('The following required parameters were', ...
            ' not provided: ''%s''.'), csmu.cell2csl(join(...
            outputInputParser.UsingDefaults(isMissingReqParam), ''', ''')));
         ME = MException(errId, errMsg);
         ME.throwAsCaller();
      end
   end
end
end