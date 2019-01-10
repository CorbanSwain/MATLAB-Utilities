classdef FigureBuilder < handle
   
    properties
        Number
        Name
        Position
        SubplotSize = [1, 1]
        PlotBuilders
        AxisConfigs
        AxisHandles
        LinkProps
    end %properties
    
    properties (GetAccess = 'private', SetAccess = 'private')
       FigureHandle
    end % private properties
    
    methods
        function h = figure(self)
            if ~isempty(self.Number)
                self.FigureHandle = figure(self.Number);
            else
                self.FigureHandle = figure;
            end
            h = self.FigureHandle;
            clf(h);
            if ~isempty(self.Name)
                h.Name = self.Name;
            end
            if  ~isempty(self.Position)
                h.Position = self.Position;
            end
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
            
            self.AxisHandles = gobjects(1, length(self.PlotBuilders));
            for iPlot = 1:length(self.PlotBuilders)
                ax = subplot(self.SubplotSize(1), ...
                   self.SubplotSize(2), iPlot);
                self.AxisHandles(iPlot) = ax;
                hold(ax, 'on');
                for iLayer = 1:length(self.PlotBuilders{iPlot})
                   self.PlotBuilders{iPlot}{iLayer}.plot(ax);
                end
                self.AxisConfigs{iPlot}.apply(ax);
            end
            
            for iLink = 1:size(self.LinkProps, 1)
               [axsIdx, props] = self.LinkProps{iLink, :};
               if isempty(axsIdx)
                  axsIdx = 1:length(self.AxisHandles);
               end
               linkprop(self.AxisHandles(axsIdx), props);
            end
            
        end % function figure(self)
        
        function save(self, varargin)
            if isempty(self.FigureHandle)
                figure(self);
            end
            self.saveFigure(self.FigureHandle, varargin{:});
        end % function save(self, varargin)
        
        function close(self)
           if ~isempty(self.FigureHandle)
              close(self.FigureHandle)
           else
              warning(['The figure cannot be closed since it has not', ...
                 ' yet ben drawn.']);
           end
        end
    end % methods
    
    methods (Static)
        function saveFigure(figureHandle, varargin)
            % saveFigure Saves the passed figure as a 300 dpi png.
            
            p = inputParser;
            p.addOptional('figureDir', 'figures', @isstr)
            p.parse(varargin{:})
            figureDir = p.Results.figureDir;
            
            if ~isdir(figureDir)
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
            filePath = fullfile(figureDir, [name, '.png']);
            % print(f, filename,'-dpng','-r300');
            % saveas(f, filename)
            csmu.FigureBuilder.exportFigWrapper(f, filePath, '-m2', ...
               '-transparent');
        end % saveFigure()
        
        function setDefaults
            % setFigureDefaults Sets default values to make pretty figures.
            if ismac
               fontSize = 18;
            else
               fontSize = 11.5;
            end
            font = 'Helvetica';
            set(groot, ...
                'defaultLineMarkerSize', 8,...
                'defaultLineLineWidth', 2, ...
                'defaultAxesFontSize', fontSize, ...
                'defaultAxesTitleFontWeight', 'normal', ...
                'defaultAxesFontName', font, ...
                'defaultAxesLabelFontSizeMultiplier', 1.1, ...
                'defaultAxesLineWidth', 2, ...
                'defaultFigureColor', [1 1 1], ...
                'defaultTextInterpreter', 'tex', ...
                'defaultTextFontSize',fontSize, ...
                'defaultTextFontName', font ...
                );
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