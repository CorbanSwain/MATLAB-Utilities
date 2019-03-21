function wrapped = linewrap(c, varargin)

ip = inputParser;
ip.addOptional('LineLength', 80, @(x) isnumeric(x));
ip.addParameter('BreakString', '\n', @(x) ischar(x) || isstring(x));
ip.parse(varargin{:});
lineLen = ip.Results.LineLength;
breakString = ip.Results.BreakString;

wrapped = c;
numChars = length(c);
locations = fliplr(lineLen:lineLen:numChars);
for iLoc = 1:length(locations)
   wrapped = insertBefore(wrapped, locations(iLoc), breakString);
end
end