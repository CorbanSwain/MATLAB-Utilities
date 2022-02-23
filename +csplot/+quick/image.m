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

function fb = image(I, varargin)
%% Meta Setup
%%% Function Metadata
fcnName = strcat('csplot.quick.', mfilename);

%%% Logging
L = csmu.Logger(fcnName);

%%% Input Handling
ip = csmu.InputParser.fromSpec({
   {'p', 'Colormap', 'magma'}
   {'p', 'ColorLimits', []}
   {'p', 'DoScaled', true}
   {'p', 'DoShowFigure', true}
   {'p', 'Title', ''}
   {'p', 'Name', ''}
   {'p', 'DoDarkMode', false}
   {'p', 'DarkMode', false}
   });
ip.FunctionName = fcnName;
ip.parse(varargin{:});
inputs = ip.Results;

doDarkMode = inputs.DoDarkMode || inputs.DarkMode;
backgroundColor = [];
foregroundColor = [];

if doDarkMode
   if isempty(backgroundColor)
      backgroundColor = ones(1, 3) * 0.05;
   end  

   if isempty(foregroundColor)
      foregroundColor = ones(1, 3) * 0.75;
   end
end

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

if ~isempty(inputs.Title)
   ax.Title = struct();
   ax.Title.String = inputs.Title;
   if ~isempty(foregroundColor)
      ax.Title.Color = foregroundColor;
   end
end

fb = csplot.FigureBuilder();
if ~isempty(backgroundColor)
   fb.Color = backgroundColor;
end
fb.AxisConfigs = [ax];
fb.PlotBuilders = {{imPlot}};

if ~isempty(inputs.Name)
   fb.Name = inputs.Name;
elseif ~isempty(inputs.Title)
   fb.Name = inputs.Title;
end

if inputs.DoShowFigure
   fb.show();
end
end