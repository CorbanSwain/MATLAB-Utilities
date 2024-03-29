classdef FigureBuilder < csmu.Object
   
   properties
      Number
      Name
      Position
      PaperSize
      Color
      Units
      SubplotSize = [1, 1]
      DoUseSubplot = false
      PlotBuilders
      AxisConfigs
      AxisHandles
      LinkProps
      LinkAxes
      Legend
   end %properties
   
   properties (GetAccess = 'public', SetAccess = 'private')
      FigureHandle
   end % private properties
   
   properties (GetAccess = 'private', SetAccess = 'private')
      LinkPropHandles
   end % private properties
   
   methods
      function set.PlotBuilders(self, val)
         if iscell(val)
            self.PlotBuilders = val;
         else
            self.PlotBuilders = csmu.tocell(val);
         end
      end
      
      function h = show(self)
         L = csmu.Logger(strcat('csplot.', mfilename, '/show'));
         if ~isempty(self.Number)
            self.FigureHandle = figure(self.Number);
         else
            self.FigureHandle = figure;
         end
         h = self.FigureHandle;
         self.FigureHandle.UserData.Links = [];
         clf(h);
         if ~isempty(self.Name)
            h.Name = self.Name;
         end
         
         if ~isempty(self.Units)
            h.Units = self.Units;
         end
         
         if ~isempty(self.Position)
            h.Position = self.Position;
         end
         
         if ~isempty(self.PaperSize)
            h.PaperSize = self.PaperSize;
         end
         
         if ~isempty(self.Color)
            h.Color = self.Color;
         end         
         
         if self.DoUseSubplot
            nSubplots = prod(self.SubplotSize);
            if  nSubplots < length(self.PlotBuilders)
               error(['The subplot dimensions are too small ', ...
                  'for the number of plots.']);
            end
            
            nAxConfigs = length(self.AxisConfigs);
            if nSubplots < nAxConfigs
               error(['The subplot dimensions are too small ', ...
                  'for the number of axis configurations.']);
            end
         else
            assert(length(self.PlotBuilders) == length(self.AxisConfigs), ...
               strcat('The number of PlotBuilder lists does not match the', ...
               ' number of axis configurations'));
         end
         
         self.AxisHandles = gobjects(1, length(self.PlotBuilders));
         for iPlot = 1:length(self.PlotBuilders)
            if self.DoUseSubplot
               ax = subplot(self.SubplotSize(1), self.SubplotSize(2), iPlot);
            else
               ax = axes('Parent', h);
            end
            self.AxisHandles(iPlot) = ax;
            hold(ax, 'on');
            for iLayer = 1:numel(self.PlotBuilders{iPlot})
               self.PlotBuilders{iPlot}{iLayer}.plot(ax);
            end           
         end
         
         for iPlot = 1:length(self.PlotBuilders)
             self.AxisConfigs(iPlot).apply(self.AxisHandles(iPlot));
         end
         
         for iLink = 1:size(self.LinkProps, 1)
            [axsIdx, props] = self.LinkProps{iLink, :};
            if isempty(axsIdx)
               axsIdx = 1:length(self.AxisHandles);
            end
            lkH = linkprop(self.AxisHandles(axsIdx), props);
            
            if isempty(self.FigureHandle.UserData.Links)
               self.FigureHandle.UserData.Links = lkH;
            else
               self.FigureHandle.UserData.Links = ...
                  [self.FigureHandle.UserData.Links, lkH];
            end
         end
         
         function test(src, evt, ax)
            set(ax, 'Ylim', get(gca, 'Xlim'))
         end
         
         for iLink = 1:size(self.LinkAxes, 1)
            [axsIdx, setting] = self.LinkAxes{iLink, :};
            if iscell(setting) 
               L.assert(length(setting) == length(axsIdx));
               if length(setting) < 2
                  continue
               end
               sourceSetting = strcat(upper(setting(1)), 'Lim');
               sourceHandle = self.AxisConfigs(axsIdx(1)).AxisHandle;
               targetSettings = csmu.cellmap(@(c) strcat(upper(c), 'Lim'), ...
                  setting(2:end));
               targetAxes = self.AxisConfigs(axsIdx(2:end));              
               for iTarget = 1:length(targetSettings)
                  targetSetting = targetSettings(iTarget);
                  targetAxis = targetAxes(iTarget);
                  targetHandle = targetAxis.AxisHandle;
                  listenerFcn = @() set(targetHandle, targetSetting, ...
                     get(sourceHandle, sourceSetting));
                  newListener = addlistener(sourceHandle, sourceSetting, ...
                     'PostSet', @(~, ~) listenerFcn());
                  targetAxis.Listeners = [targetAxis.Listeners, newListener];                  
               end                                             
            else               
               if isempty(axsIdx)
                  axsIdx = 1:length(self.AxisHandles);
               end
               linkaxes(self.AxisHandles(axsIdx), lower(setting));
            end
         end
         
         if ~isempty(self.Legend)
            self.Legend.apply;
         end
      end % function figure(self)
      
      function save(self, varargin)
         if isempty(self.FigureHandle)
            show(self);
         end
         self.saveFigure(self.FigureHandle, varargin{:});
      end % function save(self, varargin)
      
      function close(self)
         L = csmu.Logger(strcat('csplot.', mfilename, '/close'));
         for iFig = 1:length(self)
            if ~isempty(self(iFig).FigureHandle)
               close(self(iFig).FigureHandle)
            else
               L.warning(['The figure cannot be closed since it has not', ...
                  ' yet ben drawn.']);
            end
         end
      end
      
      function h = figure(self)
         L =  csmu.Logger(strcat('csplot.', mfilename, '/figure'));
         L.warn('The `figure` method is depricated, please use `show`.');
         h = self.show();
      end
   end % methods
   
   methods (Static)
      function saveFigure(figureHandle, varargin)
         % saveFigure Saves the passed figure as a 300 dpi png.
         
         p = inputParser;
         p.addOptional('figureDir', 'figures', @isstr)
         p.addParameter('ExportOptions', {'-m1', '-transparent', '-nocrop', ...
            '-png'}, @(x) iscell(x) || ischar(x) || isstring(x));
         p.parse(varargin{:})
         figureDir = p.Results.figureDir;
         exportOptions = p.Results.ExportOptions;
         
         if ~isfolder(figureDir)
            mkdir(figureDir)
         end
         
         name = '';
         switch nargin
            case 0
               f = gcf;
            otherwise
               f = figureHandle;
         end
         
         if isempty(name)
            if isempty(f.Name)
               name = 'untitled';
            else
               name = f.Name;
            end
         else
            if ~isempty(f.Name)
               name = [name, '_', f.Name];
            end
         end
         filepath = fullfile(figureDir, name);
         csplot.FigureBuilder.exportFigWrapper(f, filepath, exportOptions{:});
      end % saveFigure()
      
      function setDefaults
         % setFigureDefaults Sets default values to make pretty figures.
         if ismac
            fontSize = 18;
         else
            fontSize = 11.5;
         end
         
         % http://colorbrewer2.org/#type=qualitative&scheme=Set1&n=9
         colorOrder = [228,26,28
            55,126,184
            77,175,74
            152,78,163
            255,127,0
            215,210,40 % yellow was adjusted
            166,86,40
            247,129,191
            153,153,153] / 255;
         
         font = 'Helvetica LT Pro';
         set(groot, ...           
            'defaultLineLineWidth', 1.5, ...
            'defaultAxesFontSize', fontSize, ...
            'defaultAxesTitleFontWeight', 'normal', ...
            'defaultAxesFontName', font, ...
            'defaultAxesLabelFontSizeMultiplier', 1.1, ...
            'defaultAxesLineWidth', 2, ...
            'defaultFigureColor', [1 1 1], ...
            'defaultTextInterpreter', 'Tex', ...
            'defaultTextFontSize',fontSize, ...
            'defaultTextFontName', font, ...
            'defaultAxesColorOrder', colorOrder, ...
            'defaultAxesLineStyleOrder', {'-', '--', ':'});

      end % setFigureDefaults()
      
      function exportFigWrapper(varargin)
         exportFigPath = fullfile(csmu.extensionsDir, 'export_fig_altmany');
         cleanup = onCleanup(@() rmpath(exportFigPath));
         addpath(exportFigPath);
         export_fig(varargin{:});
         clear('cleanup');
      end
      
   end % static methods
   
end