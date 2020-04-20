%FUNCTIONNAME One-line description.
%
%   Longer, multi-line description.
%
%   Y = FUNCTIONNAME(X) operates on `X` to return `Y`.
%
%   Inputs
%      - X (1, 1) double {integer}
%      
%      Parameter/Value Pairs
%         - 'ParamName' (1, 1) double {integer}
%
%   Outputs
%      - Y the output
%
%   Notes
%      This function has special powers.
%
%   Example 1:
%   ----------
%   A cool example.
%  
%      x = magic(5);
%      y = functionName(x);
%
%   See also OTHERFUNCTIONNAME.

% AuthorFirst AuthorLast, Year

function output = hasField(fieldName, S)
fields = fieldnames(struct);
matches = strfind(fieldName, S, 'ForceCellOutput', true);
matches = cat(2, matches{:});
filteredFields = fields(matches == 1);
numFilteredFields = length(filteredFields);
if  numFilteredFields >= 1
   for iField = 1:numFilteredFields
      if strcmp(fieldName, 
   end
else
   output = false;
end
end