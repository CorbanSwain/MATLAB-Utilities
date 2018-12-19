classdef PlotBuilder < utils.DynamicShadow
   
   methods (Abstract)
      plotGraphics(self, axisHandle)
   end
   
   properties (Dependent)
      ShadowClassArgList
   end
   
   properties (NonCopyable)
      PlotHandle
   end
   
   methods      
      function plot(self, axisHandle)
         self.plotGraphics(axisHandle);
      end
      
      function out = get.ShadowClassArgList(self)
         function argList = makeArgListHelper(propList, tag)
            argList = {};
            for iProp = 1:length(propList)
               propName = propList{iProp};
               propVal = self.([tag, propName]);
               if ~isempty(propVal)
                  validPropName = propName((length(tag) + 1):end);
                  argList = [argList, {validPropName}, {propVal}];
               end
            end
         end
         
         props = self.ShadowClassRenamedPropNames;
         tags = self.ShadowClassTagCell;
         out = utils.cellmap(@(p, t) makeArgListHelper(p, t), props, tags);
         out = [out{:}];
      end
      
      function applyShadowClassProps(self, varargin)
         ip = inputParser;
         ip.addOptional('ObjectHandle', self.PlotHandle);
         ip.parse(varargin{:});
         objectHandle = ip.Results.ObjectHandle;
         
         function applyPropsHelper(propList, tag)
            for iProp = 1:length(propList)
               propName = propList{iProp};
               propVal = self.(propName);
               if ~isempty(propVal)
                  validPropName = propName((length(tag) + 1):end);
                  objectHandle.(validPropName) = propVal;
               end
            end
         end
         
         props = self.ShadowClassRenamedPropNames;
         tags = self.ShadowClassTagCell;
         cellfun(@(p, t) applyPropsHelper(p, t), props, tags);
      end
   end
   
end