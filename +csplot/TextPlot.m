classdef TextPlot < csplot.PlotBuilder
  
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
         if isempty(self.Z)
            posFun = @(i) [self.X(i), self.Y(i)];
         else
            posFun = @(i) [self.X(i), self.Y(i), self.Z(i)];
         end
         % FIXME - allow setting X and Y with Position Property
         
         function textHelper(iText)
            if isempty(self.X)
               posArgs = self.makePosition;
            else
               posArgs = posFun(iText);
            end
            
            if length(self.X) > 1
               str = csmu.loopIndexCell(self.Text, iText);
            else
               if iscell(self.Text)
                  str = self.Text{1};
               else
                  str = self.Text;
               end
            end
            if isempty(self.Units)
               textHandle = text(axisHandle, 'Position', posArgs, ...
                  'String', str);
            else
               textHandle = text(axisHandle, 'Units', self.Units, ...
                  'Position', posArgs, ...
                  'String', str);
            end
            self.applyShadowClassProps(textHandle);
         end
         
         if isempty(self.X)
            textHelper(1);
         else            
            for iText = 1:length(self.X)
               textHelper(iText);
            end
         end
      end
      
      function set.Text(self, val)
         self.Text = csmu.tocell(val);
      end

      function out = makePosition(self)
         if isempty(self.X)
            out = self.Position;
         else
            if isempty(self.Z)
               out = [self.X, self.Y];
            else
               out = [self.X, self.Y, self.Z];
            end
         end
      end
   end
   
end