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
      wbHandle = waitbar(varargin{[1, 3]});
      cleanupStruct.waitbar = onCleanup(@() close(wbHandle));
   catch ME
      L = csmu.Logger(strcat('csmu.', mfilename()));
      L.warn('Waitbar creation failed with the following error:');
      L.logException(csmu.LogLevel.WARN, ME);
      wbHandle = [];
   end
end
end