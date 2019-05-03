%PARPOOL Custom wrapper for builtin PARPOOL.   
%If any error is raised while creating the pool an empty array will be
%returned.
%
%   Syntax:
%   -------
%   pool = PARPOOL Creates or returns an existing parallel pool. The function 
%   will return an empty array if a parallel pool cannot be created or found.
%
%   pool = PARPOOL(n) Creates or returns an existing pool object with `n`
%   workers. If the existing pool object does not have `n` workers, it will
%   be stopped and a new pool with the `n` workers will be created. 
%
%   pool = PARPOOL(...) Will take any valid arguments to the builtin
%   PARPOOL and create a new pool of workers if one does not already exist.
%
%   Inputs:
%   -------
%      N - the number of workers
%          * type: numeric scalar
%          * must be an integer greater than or equal to 1
%
%   Outputs:
%   --------
%      pool - The array of workers or an empty array if parallel pool creation
%             fails.
%
%   See also PARPOOL.

% Corban Swain, 2019

function pool = parpool(varargin)
if length(varargin) == 1 && isnumeric(varargin{1}) && isscalar(varargin{1}) ...
      && varargin{1} >= 0 && csmu.isint(varargin{1})
   numWorkers = varargin{1};
else 
   numWorkers = [];
end

L = csmu.Logger(['csmu.' mfilename]);

try
   pool = gcp('nocreate');
   if ~isempty(numWorkers) && ~isempty(pool) && pool.NumWorkers ~= numWorkers
      delete(pool);
      pool = [];
   end      
   if isempty(pool)
      pool = parpool(varargin{:});
   end
catch ME
   L.info('Caught an error while attempting to start a parallel pool.');
   L.logException(csmu.LogLevel.INFO, ME);
   pool = [];
end
end