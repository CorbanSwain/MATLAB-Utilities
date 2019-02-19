classdef ScatterPlot < csmu.PlotBuilder
   properties
      X
      Y
      Z
      S
      Text
      TextBuilder = csmu.TextPlot
   end
   
   properties (Dependent)
      XY
      XYZ
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.chart.primitive.Scatter'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)
         args = {axisHandle};
         args = [args, {self.X, self.Y}];
         
         if isempty(self.Z)
            scatterFun = @(varargin) scatter(varargin{:});
         else
            scatterFun = @(varargin) scatter3(varargin{:});
            args = [args, {self.Z}];
         end
         
         if ~isempty(self.S)
            args = [args, {self.S}];
         end
         
         self.PlotHandle = scatterFun(args{:});         
         self.applyShadowClassProps;   
         
         if ~isempty(self.Text)
            self.TextBuilder.Text = self.Text;
            self.TextBuilder.X = self.X;
            self.TextBuilder.Y = self.Y;            
            self.TextBuilder.Z = self.Z;             
            self.TextBuilder.plotGraphics(axisHandle);
         end
      end
      
      function set.XYZ(self, val)
         [nRows, nCols] = size(val);
         assert(nCols == 3, 'XYZ must be a 3 column array');         
         [self.X, self.Y, self.Z] = csmu.cell2csl(mat2cell(val, nRows, ...
            [1, 1, 1]));
      end
      
      function out = get.XYZ(self)
         out = cat(2, self.X(:), self.Y(:), self.Z(:));
      end
      
      function set.XY(self, val)
         [nRows, nCols] = size(val);
         assert(nCols == 2, 'XY must be a 2 column array');         
         [self.X, self.Y] = csmu.cell2csl(mat2cell(val, nRows, [1, 1]));
      end
      
      function out = get.XY(self)
         out = cat(2, self.X(:), self.Y(:));
      end
   end
   
   methods (Static)
      function [plots] = pairedPointPlot(varargin)
         ip = inputParser;
         ip.addParameter('XY');
         ip.addParameter('DoAddArrows');
         ip.addParameter('AColor', 'r');
         ip.addParameter('BColor', 'b');
         ip.addParameter('Size', []);
         ip.addParameter('ASize', []);
         ip.addParameter('BSize', []);
         ip.addParameter('Text', []);
         ip.parse(varargin{:});
         XY = ip.Results.XY;
         doAddArrows = ip.Results.DoAddArrows;
         aColor = ip.Results.AColor;
         bColor = ip.Results.BColor;
         sz = ip.Results.Size;
         aSz = ip.Results.ASize;
         
         scatterPlotBP = csmu.ScatterPlot;
         scatterPlotBP.Marker = 'o';
         scatterPlotBP.MarkerEdgeColor = 'k';
         scatterPlotBP.MarkerFaceColor = 'w';
         scatterPlotBP.S = sz;
         
         aScatter = copy(scatterPlotBP);
         aScatter.X = XY(:, 1, 1);
         aScatter.Y = XY(:, 2, 1);
         aScatter.S = aSz;
         aScatter.MarkerEdgeColor = aColor;
         
         
         bScatter = copy(scatterPlotBP);
         bScatter.X = XY(:, 1, 2);
         bScatter.Y = XY(:, 2, 2);
         bScatter.S = bSz;
         aScatter.MarkerEdgeColor = bColor;
         
         plots = [aScatter, bScatter];
         
         if doAddArrows
            arrowPlot = csmu.QuiverPlot;
            arrowPlot.X = aScatter.X;
            arrowPlot.Y = aScatter.Y;
            arrowPlot.U = bScatter.X - aScatter.X;
            arrowPlot.V = bScatter.Y - aScatter.X;
            arrowPlot.Color = 'k';
            arrowPlot.LineWidth = 2;
            arrowPlot.MaxHeadSize = 0.2;
            arrowPlot.AutoScale = false;
            plots = [plots, arrowPlot];
         end                  
      end
   end
end