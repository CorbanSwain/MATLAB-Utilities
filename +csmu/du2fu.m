function [xf, yf] = du2fu(ax,x,y)
% DU2FU Transforms data units to normalized figure units.
pos = ax.Position;
xLimits = ax.XLim;
yLimits = ax.YLim;

xf = (x - xLimits(1)) ./ (xLimits(2) - xLimits(1));
if strcmpi(ax.XDir, 'reverse')
   xf = (pos(1) + pos(3)) - (xf * pos(3));
else
   xf = (xf * pos(3)) + pos(1);
end

yf = (y - yLimits(1)) ./ (yLimits(2) - yLimits(1));
if strcmpi(ax.YDir, 'reverse')
   yf = (pos(2) + pos(4)) - (yf * pos(4));
else
   yf = (yf * pos(4)) + pos(2);
end
end