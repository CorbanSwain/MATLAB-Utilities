%FUNCTIONNAME - One-line description.
%
%   Longer, multi-line description.
%
%   Syntax:
%   -------
%   Y = FUNCTIONNAME(X) operates on `X` to return `Y`.
%
%   Inputs:
%   -------
%      X - an input
%          * type: numeric
%
%      parameter/value pairs:
%         'ParamName' - a parameter
%
%   Outputs:
%   --------
%      Y - the output
%
%   Notes:
%   ------
%   - This function has special powers.
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

function Y = functionName(X, varargin)
%% Meta Setup
%%% Function Metadata
fcnName = strcat('', mfilename);

%%% Logging
L = csmu.Logger(fcnName);

%%% Input Handling
ip = csmu.InputParser.fromSpec({
   {'p', 'ParamName', 'defaultVal'}
   });
ip.FunctionName = fcnName;
ip.parse(varargin{:});
inputs = ip.Results;

%% Evaluation
end