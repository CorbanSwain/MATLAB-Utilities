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
end