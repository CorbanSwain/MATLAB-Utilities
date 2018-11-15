classdef BoxPlot < utils.PlotBuilder
   
   properties
      % General Properties
      X
      Groups
      LineWidth
      LineJoin
      LineStyle
      DoShowBoxPlot = true
      DoShowPoints (1, 1) logical = false
      PointsMinBinSize
      PointsMaxSpread
      PointsPlotBuilder utils.LinePlot
      DoLabelPoints
      DoShowOutlier
      
   end
   
   properties (Constant)
      PlotClass = 'utils.graphics.BoxPlot';
      PlotClassPropertyTag = '';
   end
   
   methods
      
      function plotGraphics(self, axisHandle)        
         if self.DoShowBoxPlot
            boxplot(axisHandle, self.X, self.Groups, self.PlotClassArgList{:});
            self.applyBoxLineProperties(axisHandle);
         end
         if self.DoShowPoints
            self.plotPoints(axisHandle);
         end
      end
      
      function plotPoints(self, axisHandle)
         if isvector(self.X)
            vals = self.X(:);
         else
            vals = self.X;
         end
         
         nGroups = size(vals, 2);
         [x, y] = deal(cell(1, nGroups));
         deoverlapArgs = {};
         if ~isempty(self.PointsMinBinSize)
            deoverlapArgs = {'MinBinSize', self.PointsMinBinSize};
         end
         if ~isempty(self.PointsMaxSpread)
            deoverlapArgs = [deoverlapArgs, {'MaxSpread'}, ...
               {self.PointsMaxSpread}];
         end
         
         texts = cell(1, numel(vals));
         for iGroup = 1:nGroups
            [y{iGroup}, x{iGroup}, I] = utils.deoverlapVals(vals(:, iGroup), ...
               deoverlapArgs{:});
            x{iGroup} = x{iGroup} + iGroup;
            if self.DoLabelPoints
               for iT = 1:length(I)
                  iText = sub2ind(size(vals), iT, iGroup);
                  texts{iText} = {x{iGroup}(iT), y{iGroup}(iT), ...
                     sprintf('%d', I(iT)), 'HorizontalAlignment', 'center', ...
                     'FontSize', 8, 'FontWeight', 'bold'};
               end
            end
         end
         lp = self.PointsPlotBuilder;
         if isempty(lp)
            lp = utils.LinePlot;
            lp.LineSpec = {'k.'};
            lp.MarkerSize = 10;
         end
         lp.X = x;
         lp.Y = y;
         lp.Text = texts;
         lp.plotGraphics(axisHandle);         
      end
      
      function applyBoxLineProperties(self, axisHandle)
         lineProps = {'LineWidth', 'LineStyle', 'LineJoin'};
         nLineProps = length(lineProps);
         chch = axisHandle.Children.Children;
         nChch = length(chch);
         for iChch = 1:nChch
            potentialLine = chch(iChch);          
            isLine = isa(potentialLine, 'matlab.graphics.primitive.Line') ...
                  && any(strcmpi(self.boxplotLineTags, potentialLine.Tag));
            if isLine 
               lne = potentialLine;
               for iProp = 1:nLineProps
                  propName = lineProps{iProp};
                  p = self.(propName);
                  if ~isempty(p)
                     lne.(propName) = p;
                  end
               end
            end
            
            if strcmpi('Outliers', potentialLine.Tag)
               if ~self.DoShowOutlier
                  potentialLine.Marker = 'none';
                  delete(potentialLine);
               end
            end
         end
      end
   end
         
   methods (Static)
      function out = boxplotLineTags
         out = {'Box', 'Median', 'Lower Adjacent Value', ...
            'Upper Adjacent Value', 'Lower Whisker', 'Upper Whisker'};
      end
   end
end