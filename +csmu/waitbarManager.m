function [wbHandle, cleanupStruct] = waitbarManager(varargin, nvInputs)
arguments (Repeating)
   varargin
end

arguments
   nvInputs.Cleanup
end

cleanupStruct = nvInputs.Cleanup;

try
   wbHandle = waitbar(varargin{:});
catch
   try
      % if the waitbar window was closed, create a new waitbar (ignore
      % existing hande at varargin{2}).
      wbHandle = waitbar(varargin{[1, 3]});
      cleanupStruct.waitbar = onCleanup(@() close(wbHandle));
   catch ME
      % if waitbar creation fails, log warning to the console, but 
      % still continue.
      L = csmu.Logger(strcat('csmu.', mfilename()));
      L.warn('Waitbar creation failed with the following error:');
      L.logException(csmu.LogLevel.WARN, ME);
      wbHandle = [];
   end
end
end