classdef AxisConfiguration < handle
   
   properties
      Grid
      TitleInterpreter
   end
   
   methods
      function apply(self, axisHandle)
         specialProps = {};
         function addToSpecialProps(prop)
            specialProps = [specialProps, {prop}];
         end
         
         currentProp = 'Grid';
         addToSpecialProps(currentProp);
         if ~isempty(self.Grid)
            grid(axisHandle, self.Grid);
         end
         
         currentProp = 'Title';
         addToSpecialProps(currentProp);
         if ~isempty(self.Title)
            title(axisHandle, self.Title, 'Interpreter', ...
               self.TitleInterpreter);
         end
         
         isYYPropFun = @(name, val) startsWith(name, 'Y') && iscell(val) ...
            && length(val) == 2;
         axisProps = self.axisProperties;
         for iProp = 1:length(axisProps)
            propName = axisProps{iProp};
            propVal = self.(propName);
            isYYProp = isYYPropFun(propName, propVal);
            if ~isempty(propVal) && ~any(strcmpi(propName, specialProps))
               if ~isYYProp
                  axisHandle.(propName) = propVal;
               else
                  yyaxis(axisHandle, 'left');
                  axisHandle.(propName) = propVal;
                  yyaxis(axisHandle, 'right');
                  axisHandle.(propName) = propVal;
                  yyaxis(axisHandle, 'left');
               end
            end
         end
      end
   end
   
   methods (Static)
      function p = axisProperties
         p = properties(matlab.graphics.axis.Axes);
      end
   end
end