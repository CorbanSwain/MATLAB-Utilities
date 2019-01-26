classdef LinePlot < csmu.PlotBuilder
   
   properties
      X
      Y
      Z
      LineSpecCycleLength
      ColorOrderCycleLength
      LineSpec = {'-'} % setter update cell length
      % MarkerSize % setter update cell length
      % MarkerFaceColor % setter update cell length
      FillMarker = true
      % LineWidth % setter update cell length
      LegendLabels
      LegendLineWidth = 1.5
      LegendLocation = 'best'
      LegendColumns = 1
      LegendBox = 'on'
      LegendTitle
      YError
      AxisAssignment
      Text
   end
   
   properties
      PointPairs
   end
   
   properties (Constant)
      ShadowClass = {'matlab.graphics.chart.primitive.Line', ...
         'matlab.graphics.chart.primitive.ErrorBar'}
      ShadowClassTag = {'', 'ErrBar'}
      ShadowClassExcludeList = {{''}, {''}}
   end
   
   methods
      function set.X(self, val)
         self.X = csmu.tocell(val);
      end
      
      function set.Y(self, val)
         self.Y = csmu.tocell(val);
      end
      
      function self = csmu.LinePlot(X, Y)
         if nargin == 2
            self.X = X;
            self.Y = Y;
         end
      end
      
      function plotGraphics(self, axisHandle)
         if isempty(self.Y)
            error('Y-Values must be passed to build a plot.');
         end
         nYVals = length(self.Y);
         if isempty(self.X)
            for i = 1:nYVals
               self.X{i} = 1:length(self.Y{i});
            end
         end
         if  nYVals ~= length(self.X)
            if length(self.X) == 1
               Xtemp = self.X{1};
               self.X = cell(nYVals, 1);
               [self.X{:}] = deal(Xtemp);
            else
               error('x and y cell arrays have mismatched dimensions.');
            end
         end

         plotSettingNames = {'MarkerSize','MarkerFaceColor', ...
            'LineWidth', 'Color'};
         lineSpecIndex = 1;
         for i = 1:nYVals
            % FIXME - maybe functionalize this more? Be able to take in
            % shorter cell arrays then vars.
            if ~isempty(self.AxisAssignment)
               % FIXME - Check self.AxisAssignment has length equal to
               % nYVals
               if self.AxisAssignment(i) == 1
                  yyaxis(axisHandle, 'left');
               else
                  yyaxis(axisHandle, 'right');
               end
               % FIXME - handle incorrectly formatted axes assignment
               % value
            end
            
            if ~isempty(self.YError) && ~isempty(self.YError{i})
               h = errorbar(axisHandle, self.X{i}, self.Y{i}, ...
                  self.YError{i}, self.LineSpec{lineSpecIndex});
            else
               h = plot(axisHandle, self.X{i}, self.Y{i}, ...
                  self.LineSpec{lineSpecIndex});
            end
            self.PlotHandle = [self.PlotHandle, h];
            
            hold(axisHandle,'on');
            h.AlignVertexCenters = 'on';
            
            if ~isempty(self.ColorOrderCycleLength)
               if (mod(i, self.ColorOrderCycleLength) == 0)
                  axisHandle.ColorOrderIndex = 1;
               end
            end
            
            if ~isempty(self.LineSpecCycleLength)
               if (mod(i, self.LineSpecCycleLength) == 0)
                  lineSpecIndex = lineSpecIndex + 1;
               end
            else
               if length(self.LineSpec) > 1
                  lineSpecIndex = lineSpecIndex + 1;
               end
            end
            
            if isempty(self.MarkerFaceColor)
               if self.FillMarker
                  h.MarkerFaceColor = h.Color;
               end
            end
            
            for iSetting = 1:length(plotSettingNames)
               name = plotSettingNames{iSetting};
               propertyVal = self.(name);
               if ~isempty(propertyVal)
                  if iscell(propertyVal)
                     h.(name) = propertyVal{i};
                  else
                     h.(name) = propertyVal;
                  end
               end
            end
            
         end  
         
         if ~isempty(self.LegendLabels)
            lgd = legend(self.LegendLabels);
            if ~isempty(self.LegendTitle)
               title(lgd, self.LegendTitle);
            end
            lgd.LineWidth = self.LegendLineWidth;
            lgd.Location = self.LegendLocation;
            lgd.Box = self.LegendBox;
            try
               lgd.NumColumns = self.LegendColumns;
            catch
               if self.LegendColumns > 1
                  warning(['No NumColumns property of legend,', ...
                     ' using Orientation instead.'])
                  lgd.Orientation = 'horizontal';
               end
            end
         end
         
         for i = 1:length(self.Text)
            text(axisHandle, self.Text{i}{:})
         end
      end
   end
   
end