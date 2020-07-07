%RMEMPTYFIELDS One-line description.
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

function output = rmEmptyFields(S)
fields = fieldnames(S);
filter = structfun(@isempty, S);
output = rmfield(S, fields(filter));
end