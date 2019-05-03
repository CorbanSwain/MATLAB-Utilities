classdef LineBuilder < csplot.PlotBuilder
   
   properties
      X
      Y
      Z
   end
   
   properties (Dependent)
      PointPairList
   end
   
   properties (Constant)
      ShadowClass= 'matlab.graphics.chart.primitive.Line'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods
      function set.X(self, val)
         self.X = csmu.tocell(val);
      end
      
      function set.Y(self, val)
         self.Y = csmu.tocell(val);
      end
      
      function set.Z(self, val)
         self.Z = csmu.tocell(val);
      end
      
      function set.PointPairList(self, val)
         [nPoints, nDims] = size(val);        
         PCell = mat2cell(val, repmat(2, 1, nPoints / 2), ones(1, nDims));
         self.X = PCell(:, 1);
         self.Y = PCell(:, 2);
         if nDims > 2
            self.Z = PCell(:, 3);
         end
      end
      
      function plotGraphics(self, axisHandle)
         
         if isempty(self.Z)
            pointArgsFun = @(i) {self.X{i}, self.Y{i}};
         else
            pointArgsFun = @(i) {self.X{i}, self.Y{i}, self.Z{i}};
         end
         
         nLines = size(self.Y, 1);
         self.PlotHandle = gobjects(1, nLines);
         function lineHelper(iLine)
            pointArgs = pointArgsFun(iLine);
            h = line(axisHandle, pointArgs{:});
            self.PlotHandle(iLine) = h;
            self.applyShadowClassProps(h);
         end
         
         for iLine = 1:nLines
            lineHelper(iLine);
         end
      end
   end
   
end