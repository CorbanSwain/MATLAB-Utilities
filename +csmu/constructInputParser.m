function outputInputParser = constructInputParser(parserSpec, varargin)
ip = inputParser;
ip.FunctionName = mfilename;
ip.addParameter('Name', '', @csmu.validators.scalarStringLike);
ip.addParameter('Args', [], @iscell);
ip.parse(varargin{:});
ip = ip.Results;
functionName = ip.Name;
inputArgs = ip.Args;

outputInputParser = inputParser;
outputInputParser.FunctionName = functionName;
for iSpec = 1:length(parserSpec)
   spec = parserSpec{iSpec};
   args = spec(2:end);
   switch spec{1}
      case 'r'
         outputInputParser.addRequired(args{:});         
      case 'o'
         outputInputParser.addOptional(args{:});         
      case 'p'
         outputInputParser.addParameter(args{:});
   end
end

if ~isempty(inputArgs)
   outputInputParser.parse(inputArgs{:});
end
end