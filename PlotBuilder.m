classdef PlotBuilder < matlab.mixin.Copyable
   
   properties
      XLim
      YLim
      XLabel
      YLabel
      XScale
      YScale
      Grid
      Box
      Title
      TitleInterpreter
      XGrid
      YGrid
   end
   
   properties (NonCopyable)
      PlotHandle
   end
   
   methods (Abstract)
      plot(self, axisHandle)
   end
   
   methods 
      function applyStandardProps(self, axisHandle)
         if ~isempty(self.Box)
            box(axisHandle, self.Box)
         end
         if ~isempty(self.Grid)
            grid(axisHandle, self.Grid);
         end
         if ~isempty(self.XLabel)
            xlabel(self.XLabel);
         end
         if ~isempty(self.YLabel)
            if iscell(self.YLabel)
               yyaxis(axisHandle, 'left');
               ylabel(self.YLabel{1});
               yyaxis(axisHandle, 'right');
               ylabel(self.YLabel{2});
            else
               ylabel(self.YLabel);
            end
         end
         if ~isempty(self.XLim)
            xlim(self.XLim);
         end
         if ~isempty(self.YLim)
            if iscell(self.YLim)
               yyaxis(axisHandle, 'left');
               ylim(self.YLim{1});
               yyaxis(axisHandle, 'right');
               ylim(self.YLim{2});
            else
               ylim(self.YLim);
            end
         end
         if ~isempty(self.XScale)
            axisHandle.XScale = self.XScale;
         end
         if ~isempty(self.YScale)
            axisHandle.YScale = self.YScale;
         end
         if ~isempty(self.Title)
            title(axisHandle, self.Title, 'Interpreter', ...
               self.TitleInterpreter);
         end
         
         axisProps = {'XGrid', 'YGrid'};
         for iProp = 1:length(axisProps)
            propName = axisProps{iProp};
            selfProp = self.(propName);
            if ~isempty(selfProp)
               axisHandle.(propName) = selfProp;
            end
         end
      end
   end
   
end