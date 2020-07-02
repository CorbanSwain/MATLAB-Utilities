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

function output = durationString(x, varargin)
%% Meta Setup
%%% Function Metadata
fcnName =  strcat('csmu.', mfilename);

%%% Logging
L = csmu.Logger(fcnName);

%%% Input Handling
parserSpec = {
   {'p', 'DurationFcn', @seconds}
   {'p', 'DurationFmt', 'mm:ss.SS'}
   {'p', 'Suffix', ' min:sec'}
};
ip = csmu.constructInputParser(parserSpec, 'Name', fcnName, 'Args', varargin);
inputs = ip.Results;

%% Implementation
output = sprintf('%s%s', string(inputs.DurationFcn(x), inputs.DurationFmt), ...
   inputs.Suffix);
end