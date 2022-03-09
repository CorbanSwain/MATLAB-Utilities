function notImplemented(varargin)
ME = MException('csmu:validators:notImplemented', ...
   sprintf('Handling of value is not implemented; do not set.'));
throw(ME);
end