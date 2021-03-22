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
            msg = strcat('All array arguments must have equal lengths', ...
               ' (passed lengths were: [%s]).');
            passedLengths = cellfun(@(x) length(x), varargin(1:(end - 1)));
            ME = ME.addCause(MException(errorId, msg, num2str(passedLengths)));
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