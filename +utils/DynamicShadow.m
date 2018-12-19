classdef DynamicShadow < dynamicprops & matlab.mixin.Copyable
   
   properties
      DynamicShadowProps
   end
   
   properties (Abstract, Constant)
      ShadowClass
      ShadowClassTag
      ShadowClassExcludeList
   end
   
   properties (Dependent)
      ShadowClassTagCell
      ShadowClassCell
      ShadowClassExcludeListCell
      AllDynamicShadowPropNames
      ShadowClassRenamedPropNames
      ShadowClassOriginalPropNames
   end
   
   methods
      function self = DynamicShadow
         cellfun(@(p) self.addDynamicShadowProp(p), ...
            self.AllDynamicShadowPropNames);
      end
      
      function addDynamicShadowProp(self, propName)         
         dpObject = self.addprop(propName);
         dpObject.NonCopyable = false;
         self.DynamicShadowProps = [self.DynamicShadowProps, dpObject];
      end
      
      function out = get.ShadowClassCell(self)
         out = utils.tocell(self.ShadowClass);
      end
      
      function out = get.ShadowClassTagCell(self)
         out = utils.tocell(self.ShadowClassTag);
      end
      
      function out = get.ShadowClassExcludeListCell(self)
         out = utils.tocell(self.ShadowClassExcludeList, 2);
      end
      
      function out = get.AllDynamicShadowPropNames(self)
         out = vertcat(self.ShadowClassRenamedPropNames{:});
      end
      
      function out = get.ShadowClassRenamedPropNames(self)
         out = utils.cellmap(@(pcell, t, exclude) ...
            utils.cellmap(@(p) strcat(t, p), ...
            setdiff(pcell, exclude, 'stable')), ...
            self.ShadowClassOriginalPropNames, self.ShadowClassTagCell, ...
            self.ShadowClassExcludeListCell);
      end
      
      function out = get.ShadowClassOriginalPropNames(self)
        out = utils.cellmap(@(c) properties(c), self.ShadowClassCell);
      end
   end
      
end