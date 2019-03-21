classdef DefaultPlotBuilder < csmu.PlotBuilder
   properties (Constant)
      ShadowClass = ''
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods 
      function self = DefaultPlotBuilder(varargin)
         if nargin
            sz = csmu.parseSizeArgs(varargin{:});
            if isempty(sz) || any(cell2mat(sz) == 0)
               self = csmu.DefaultPlotBuilder.empty(sz{:});
            else
               self(sz{:}) = copy(self);
            end
         end
      end
      
      function plotGraphics(~, ~)
         L = csmu.Logger('DefaultPlotBuilder.plotGraphics');
         L.warn(['Attempting to plot a DefaultPlotBuilder object; ', ...
            'however, no plot can be created.\nCheck that all objects in ', ...
            'the PlotBuilder array are properly set to non-abstract ', ...
            'PlotBuilder objects.']);
      end
   end   
end