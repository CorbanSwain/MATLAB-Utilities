function mustBeVector(A, varargin)
ip = inputParser;
ip.addOptional('length', [], @isvector);
ip.parse(varargin{:});
allowedLengths = ip.Results.length;
isOK = isvector(A) || (ismember(0, allowedLengths) && isempty(A));
if ~isempty(ip.Results.length)
   isOK = isOK && ismember(length(A), allowedLengths);
end
if ~isOK
    ME = MException('utils:validators:mustBeVector', ...
       sprintf('Value must be a vector with length %s.', ...
       num2str(allowedLengths)));
   throw(ME);
end
end