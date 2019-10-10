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
      case parameterFlags
         outputInputParser.addParameter(args{:});
   end
end

if iscell(inputArgs)
   outputInputParser.parse(inputArgs{:});
end
end