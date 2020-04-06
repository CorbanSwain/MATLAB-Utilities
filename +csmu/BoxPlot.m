classdef BoxPlot < csmu.PlotBuilder
   
   properties
      % General Properties
      X
      Groups
      LineWidth = 2
      LineJoin
      LineStyle
      DoShowBoxPlot = true
      DoShowPoints (1, 1) logical = false
      PointsMinBinSize
      PointsMaxSpread = 0.75
      PointsPlotBuilder csmu.ScatterPlot
      DoLabelPoints
      DoShowOutlier
      DefaultColor
   end
   
   properties (Constant)
      ShadowClass = 'csmu.graphics.BoxPlot'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods
      
      function plotGraphics(self, axisHandle)        
         if self.DoShowBoxPlot
            args = self.ShadowClassArgList;
            if isempty(self.Colors) && ~isempty(self.DefaultColor)
               args = [args, {'Colors', self.DefaultColor}];
            end
            boxplot(axisHandle, self.X, self.Groups, args{:});
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
         deoverlapArgs = {};
         if ~isempty(self.PointsMinBinSize)
            deoverlapArgs = {'MinBinSize', self.PointsMinBinSize};
         end
         if ~isempty(self.PointsMaxSpread)
            deoverlapArgs = [deoverlapArgs, {'MaxSpread'}, ...
               {self.PointsMaxSpread}];
         end
         
         scatterPlot = copy(self.PointsPlotBuilder);         
         if isempty(scatterPlot)
            scatterPlot = csmu.ScatterPlot;
         end
         
         if isempty(scatterPlot.Marker)
            scatterPlot.Marker = 'o';
         end
         
         if isempty(scatterPlot.S)
            scatterPlot.S = 200;
         end

         if isempty(scatterPlot.LineWidth)
            scatterPlot.LineWidth = 2;
         end

         
         if isempty(scatterPlot.MarkerEdgeColor)
            if ~isempty(self.DefaultColor)
               scatterPlot.MarkerEdgeColor = self.DefaultColor;
            else
               scatterPlot.MarkerEdgeColor = 'k';
            end
         end   
         
         if isempty(scatterPlot.MarkerFaceColor)
            scatterPlot.MarkerFaceColor = 'w';
         end                              
         
         if self.DoLabelPoints
            textPlot = csmu.TextPlot;
            textPlot.HorizontalAlignment = 'center';
            textPlot.FontSize = 8;
            textPlot.FontWeight = 'bold';
            if ~isempty(self.DefaultColor)
               textPlot.Color = self.DefaultColor;
            end
            scatterPlot.TextBuilder = textPlot;
         end
         
         [ys, xs, Is] = csmu.deoverlapVals(vals, deoverlapArgs{:});
         for iGroup = 1:nGroups
            iScatterPlot = copy(scatterPlot);
            x = xs(:, iGroup);
            y = ys(:, iGroup);
            I = Is(:, iGroup);
            x = x + iGroup;
            if self.DoLabelPoints
               texts = cell(1, length(I));
               for iText = 1:length(I)
                  texts{iText} = sprintf('%d', I(iText));
               end
               iScatterPlot.Text = texts;
            end   
            if ~isempty(self.Colors)
               currentColor = self.Colors(iGroup, :);
               iScatterPlot.MarkerEdgeColor = currentColor;
               iScatterPlot.MarkerFaceColor = currentColor;
            end
            iScatterPlot.X = x;
            iScatterPlot.Y = y;
            iScatterPlot.plotGraphics(axisHandle);
         end
    
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