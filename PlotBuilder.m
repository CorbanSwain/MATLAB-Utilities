classdef PlotBuilder < dynamicprops & matlab.mixin.Copyable
   
   properties (Constant, Abstract)
      PlotClass
      PlotClassPropertyTag
   end

   methods (Abstract)
      plotGraphics(self, axisHandle)
   end     
   

   
   properties (Dependent)
      PlotClassProperties
      PlotClassArgList
   end
   
   properties (NonCopyable)
      PlotHandle
   end
   
   methods
      function self = PlotBuilder
         if ~iscell(self.PlotClassPropertyTag)
            cellfun(@(p) self.addprop(strcat(self.PlotClassPropertyTag, p)), ...
               self.PlotClassProperties);
         else
            cellfun(@(t, pcell) ...
               cellfun(@(p) self.addprop(strcat(t, p)), pcell), ...
               self.PlotClassPropertyTag, self.PlotClassProperties); 
         end
      end
      
      function plot(self, axisHandle)
         self.plotGraphics(self, axisHandle);
      end
      
      function out = get.PlotClassProperties(self)
         if ~iscell(self.PlotClass)
            out = properties(self.PlotClass);
         else
            out = utils.cellmap(@(c) properties(c), self.PlotClass);
         end
      end
      
      function out = get.PlotClassArgList(self)
         function argList = makeArgListHelper(propList, tag)
            argList = {};
            for iProp = 1:length(propList)
               propName = propList{iProp};
               propVal = self.([tag, propName]);
               if ~isempty(propVal)
                  argList = [argList, {propName}, {propVal}];
               end
            end
         end
      
         props = self.PlotClassProperties;
         tags = self.PlotClassPropertyTag;
         if ~iscell(tags)
            out = makeArgListHelper(props, tags);
         else
            out = utils.cellmap(@(p, t) makeArgListHelper(p, t), props, tags);
         end
      end
      
      function applyPlotClassProps(self, varargin)
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
         
         props = self.PlotClassProperties;
         tags = self.PlotClassPropertyTag;
         if ~iscell(tags)
            applyPropsHelper(props, tags)
         else
            cellfun(@(p, t) applyPropsHelper(p, t), props, tags);
         end
      end
   end
   
end