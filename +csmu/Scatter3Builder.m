classdef Scatter3Builder < csmu.PlotBuilder
   properties
      X
      Y
      Z
      S
      Text
      TextBuilder = csmu.TextPlot
   end
   
   properties (Dependent)
      XYZ
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.chart.primitive.Scatter'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)
         self.PlotHandle = scatter3(axisHandle, self.X, self.Y, self.Z, self.S);         
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
            [1 1 1]));
      end
      
      function out = get.XYZ(self)
         out = cat(2, self.X(:), self.Y(:), self.Z(:));
      end
   end
end