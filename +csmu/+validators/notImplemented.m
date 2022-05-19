function notImplemented(varargin)
if ~(nargin() == 1 && isempty(varargin{1}) && isa(varargin{1}, 'double'))
ME = MException('csmu:validators:notImplemented', ...
   sprintf('Handling of value is not implemented; do not set.'));
throw(ME);
end
end