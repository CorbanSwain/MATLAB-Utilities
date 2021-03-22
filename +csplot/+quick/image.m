%IMAGE - One-line description.
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

function fig = image(I, varargin)
%% Meta Setup
%%% Function Metadata
fcnName = strcat('csplot.quick.', mfilename);

%%% Logging
L = csmu.Logger(fcnName);

%%% Input Handling
parserSpec = {
   {'p', 'Colormap', 'magma'}
   {'p', 'ColorLimits', []}
   {'p', 'DoScaled', true}
   {'p', 'DoShowFigure', true}
   };
ip = csmu.constructInputParser(parserSpec, 'Name', fcnName, 'Args', varargin);
inputs = ip.Results;

%% Evaluation

I = csmu.Image(I);

imPlot = csplot.ImagePlot();
imPlot.I = I.I;
imPlot.Colormap = inputs.Colormap;
imPlot.ColorLimits = inputs.ColorLimits;
imPlot.DoScaled = inputs.DoScaled;

ax = csplot.AxisConfiguration();
gs = csplot.GridSpec(1, 1);
ax.Position = gs(1);
ax.YDir = 'reverse';
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';
ax.XLim = [1, I.Size(2)] + [-0.5, +0.5];
ax.YLim = [1, I.Size(1)] + [-0.5, +0.5];
ax.DataAspectRatio = [1, 1, 1];

fig = csplot.FigureBuilder();
fig.AxisConfigs = [ax];
fig.PlotBuilders = {{imPlot}};

if inputs.DoShowFigure
   fig.show();
end
end