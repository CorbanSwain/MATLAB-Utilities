classdef Legend < csmu.DynamicShadow
   
   properties
      AxisHandle
      SubsetObjects
   end
   
   properties (NonCopyable)
      LegendHandle
   end
   
   properties (Dependent)
      Labels
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.illustration.Legend'
      ShadowClassTag = ''
      ShadowClassExcludeList = ''
   end
   
   methods
      function self = Legend(labels)
         self = self@csmu.DynamicShadow;
         if nargin
            self.Labels = labels;
         end
      end
      
      function apply(self, varargin)
         % FIXME - allow for setting the title
         
         ip = inputParser;
         ip.addOptional('Target', []);
         ip.addOptional('Subset', []);
         ip.parse(varargin{:});
         target = ip.Results.Target;
         subset = ip.Results.Subset;
         if isempty(target)
            target = self.AxisHandle;
         end         
         if isempty(subset)
            subset = self.SubsetObjects;
         end
        
         args = cell(1, 0);
         if ~isempty(target)
            switch class(target)
               case 'csplot.AxisConfiguration'
                  target = target.AxisHandle;
                  
               case 'matlab.graphics.axis.Axes'
                  % dont need to do anything
               
               otherwise
                  error('Unexpected input for legend target.');
            end
            args = [args, {target}];
         end         
         if ~isempty(subset)
            if isa(subset, 'csplot.PlotBuilder')
               properSubset = gobjects(size(subset));
               for iObj = 1:numel(subset)
                  properSubset(iObj) = subset(iObj).PlotHandle(1);
               end
               subset = properSubset;               
            elseif isa(subset, 'matlab.graphics.GraphicsPlaceholder')
                  % everything is good                  
            elseif isa(subset, 'cell')
               properSubset = gobjects(size(subset));
               for iObj = 1:numel(subset)
                  obj = subset{iObj};
                  if isa(obj, 'function_handle')
                     properSubset(iObj) = obj();
                  elseif isa(obj, 'csplot.PlotBuilder')
                     properSubset(iObj) = obj.PlotHandle(1);
                  else
                     properSubset(iObj) = obj;
                  end
               end
               subset = properSubset;               
            else
               error('Unexpected input for legend subset.');
            end         
            args = [args, {subset}];
         end         
         args = [args, self.ShadowClassArgList];
         self.LegendHandle = legend(args{:});
      end
      
      function set.Labels(self, val)
         self.String = val;
      end
      
      function out = get.Labels(self)
         out = self.String;
      end
   end
   
end