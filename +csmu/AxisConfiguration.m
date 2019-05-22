classdef AxisConfiguration < csmu.DynamicShadowOld
   
   properties
      Grid
      TitleInterpreter = 'none'      
      PBAspect
      Legend
   end
   
   properties (Constant)
      ShadowClass = 'matlab.graphics.axis.Axes'
      ShadowClassTag = ''
      ShadowClassExcludeList = 'Legend'
   end
   
   properties (NonCopyable)
      AxisHandle
   end
   
   properties (Dependent)
      Tick
   end
   
   methods
      function self = AxisConfiguration(varargin)
         if nargin
            sizeCell = csmu.parseSizeArgs(varargin{:});
            % FIXME - need to handle empty arrays
            self(sizeCell{:}) = csmu.AxisConfiguration;
            for iAc = 1:numel(self)
               self(iAc) = csmu.AxisConfiguration;
            end
         end
      end
      
      function apply(self, axisHandle)
         self.AxisHandle = axisHandle;
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
         
         currentProp = {'XAxis', 'YAxis', 'ZAxis'};
         addToSpecialProps(currentProp);
         for iProp = 1:length(currentProp)
            pName = currentProp{iProp};
            pVal = self.(pName);
            if isstruct(pVal)
               fNames = fieldnames(pVal);
               for iField = 1:length(fNames)
                  fName = fNames{iField};
                  axisHandle.(pName).(fName) = pVal.(fName);
               end
            elseif isempty(pVal)
               
            else
               L.error('Unexpected value provided for %s', pName);
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
                  if ~any(strcmpi(propName, {'xlabel', 'ylabel', 'zlabel'}))
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
         
         if ~isempty(self.Legend)
            self.Legend.apply(axisHandle);
         end
      end
      
      
      function set.Tick(self, val)
         self.XTick = val;
         self.YTick = val;
         self.ZTick = val;         
      end
   end

   methods (Static)
      function fb = makeProjViewFigure(varargin)
         ip = inputParser;
         ip.addParameter('ImageRef', []);
         ip.addParameter('AxisRoundingFactor', 50);
         ip.addParameter('TickRoundingFactor', 50);
         ip.addParameter('Margin', 0.1);
         ip.addParameter();
         ip.parse(varargin{:});
         imrefIn = ip.Results.ImageRef;
         axisRoundingFactor = ip.Results.AxisRoundingFactor;
         if isscalar(imrefIn) == 1
            imref = csmu.ImageRef(imrefIn);
         else
            imref(1, length(imrefIn)) = csmu.ImageRef;
            for iRef = 1:length(imref)
               imref(iRef) = csmu.ImageRef(imrefIn(iRef));
            end
         end
         allImLims = zeros(2, 3);
         for iRef = 1:length(imref)
            lims = reshape(cat(2, imref(iRef).WorldLimits{:}), 2, []);
            if iRef == 1
               allImLims = lims;
            else
               allImLims(1, :) = min(lims(1, :), allImLims(1, :));
               fullLime(2, :) = max(lims(2, :), fullLime(2, :));
            end
         end
         axisEdgeLengths = ceil(diff(allImLims / axisRoundingFactor, 1, 1));
         axisLims = mean(lims, 1) ...
            + (axisEdgeLengths * axisRoundingFactor / 2 .* [-1; 1]);
         
         roundFun = @(x, val) val * round(x / val);
         roundVal = 200;
         ticks = colon(roundFun(min(axisLims(:)), roundVal), roundVal, ...
            roundFun(max(axisLims(:)), roundVal));
         pad = 3;
         gap = 1;
         
         ncols = sum(axisEdgeLengths([1, 3])) + gap + (pad * 2);
         nrows = sum(axisEdgeLengths([2, 3])) + gap + (pad * 2);
         
         gs = csmu.GridSpec(nrows, ncols, 'Left', 0, 'Bottom', 0, 'Right', 0, ...
            'Top', 0, 'HSpace', 0, 'VSpace', 0);
         
         xyPanel = {(1:axisEdgeLengths(2)) + pad, ...
            (1:axisEdgeLengths(1)) + pad};
         yzPanel = {xyPanel{1}, ...
            xyPanel{2}(end) + gap + (1:axisEdgeLengths(3))};
         xzPanel = {xyPanel{1}(end) + gap + (1:axisEdgeLengths(3)), ...
            xyPanel{2}};
         legendPanel = cell(1, 2);
         legendPanel{2} = yzPanel{2};
         legendPanel{1} = xzPanel{1}(1):xzPanel{1}(floor(end/5));
         textPanel = cell(1, 2);
         textPanel{2} = legendPanel{2};
         textPanel{1} = (legendPanel{1}(end) + 1):xzPanel{1}(end);
         
         
      end
   end
   
end