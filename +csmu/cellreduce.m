function output = cellreduce(reduceFcn, varargin)

%% Input Handling
narginchk(1, +inf);
if length(varargin) == 1
   reduceLength = length(varargin{1});
   if reduceLength == 0
      output = [];
      return;
   else
      initialInput = varargin{1}{1};
      argsArray = varargin{1}(2:end);
   end
else
   try
      argsArray = cat(1, varargin{1:(end - 1)});
   catch ME
      switch ME.identifier
         case 'MATLAB:catenate:dimensionMismatch'
            errorId = 'CSMU:cellreduce:dimensionMismatch';
            msg = strcat(['All array arguments cellreduce must be row vector ' ...
               'cell arrays of equal lengths (passed sizes were: [%s]).']);
            passedSizeStrs = ...
               csmu.cellmap(@(x) ['[' num2str(size(x)) ']'], ...
               varargin(1:(end - 1)));
            ME = ME.addCause(...
               MException(errorId, msg, cell2mat(join(passedSizeStrs, ', '))));
      end
      throw(ME);
   end
   initialInput = varargin{end};
end


%% Computation
output = initialInput;
for args = argsArray
   output = reduceFcn(output, args{:});
end
end