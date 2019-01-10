classdef AxisConfiguration < csmu.DynamicShadow
   
   properties
      Grid
      TitleInterpreter = 'none'      
      PBAspect
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.axis.Axes'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods            
      function apply(self, axisHandle)
         specialProps = {};
         function addToSpecialProps(prop)
            specialProps = [specialProps, csmu.tocell(prop)];
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
         
         currentProp = {'XLim', 'YLim', 'ZLim'};
         addToSpecialProps(currentProp);
         for iProp = 1:length(currentProp)
            pName = currentProp{iProp};
            pVal = self.(pName);
            if ~isempty(pVal)
               if ~strcmpi(pVal, 'auto')
                  axisHandle.(pName) = pVal;
               else
                  axisHandle.(pName) = [-inf inf];
               end
            end
         end
         
         isYYPropFun = @(name, val) startsWith(name, 'Y') && iscell(val) ...
            && length(val) == 2;
         axisProps = self.AllDynamicShadowPropNames;
         for iProp = 1:length(axisProps)
            propName = axisProps{iProp};
            propVal = self.(propName);
            isYYProp = isYYPropFun(propName, propVal);
            if ~isempty(propVal) && ~any(strcmpi(propName, specialProps))
               if ~isYYProp
                  if ~endsWith(propName, 'label', 'IgnoreCase', true)
                     axisHandle.(propName) = propVal;
                  else
                     axisHandle.(propName).String = propVal;
                  end
               else
                  if ~endsWith(propName, 'label', 'IgnoreCase', true)
                     yyaxis(axisHandle, 'left');
                     axisHandle.(propName) = propVal{1};
                     yyaxis(axisHandle, 'right');
                     axisHandle.(propName) = propVal{2};
                     yyaxis(axisHandle, 'left');
                  else
                     yyaxis(axisHandle, 'left');
                     axisHandle.(propName).String = propVal{1};
                     yyaxis(axisHandle, 'right');
                     axisHandle.(propName).Strin = propVal{2};
                     yyaxis(axisHandle, 'left');
                  end

               end
            end
         end
         
         if ~isempty(self.PBAspect)
            pbaspect(axisHandle, self.PBAspect)
         end
      end
   end

end