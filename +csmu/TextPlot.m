classdef TextPlot < csmu.PlotBuilder
  
   properties
      X
      Y
      Z
      Text
   end
   
   properties (Constant)
     ShadowClass = 'matlab.graphics.primitive.Text'
     ShadowClassTag = ''
     ShadowClassExcludeList = ''
   end
   
   methods
      function plotGraphics(self, axisHandle)               
         disp(self.X(1))
         if isempty(self.Z)
            posFun = @(i) {self.X(i), self.Y(i)};
         else
            posFun = @(i) {self.X(i), self.Y(i), self.Z(i)};
         end
         
         function textHelper(iText)
            posArgs = posFun(iText);
            if length(self.X) > 1
               str = csmu.loopIndexCell(self.Text, iText);
            else
               str = self.Text;
            end         
            textHandle = text(axisHandle, posArgs{:}, str);
            self.applyShadowClassProps(textHandle);
         end         
         
         for iText = 1:length(self.X)
            textHelper(iText);
         end
      end
      
      function set.Text(self, val)
         self.Text = csmu.tocell(val);
      end

   end
   
end