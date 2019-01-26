function mustBeVector(A, varargin)
ip = inputParser;
ip.addOptional('allowedLengths', [], @isvector);
ip.parse(varargin{:});
allowedLengths = ip.Results.allowedLengths;
isOK = isvector(A) || (ismember(0, allowedLengths) && isempty(A));
if ~isempty(allowedLengths)
   isOK = isOK && ismember(length(A), allowedLengths);
end
if ~isOK
    ME = MException('csmu:validators:mustBeVector', ...
       sprintf('Value must be a vector with length(s) [%s].', ...
       num2str(allowedLengths)));
   throw(ME);
end
end