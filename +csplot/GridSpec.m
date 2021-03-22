classdef GridSpec < csmu.Object
   properties
      NumRows (1, 1) {mustBeNumeric} = 1
      NumColumns (1, 1) {mustBeNumeric} = 1
      VSpace (1, 1) {mustBeNumeric} = 0.075
      HSpace (1, 1) {mustBeNumeric}  = 0.075
      Top (1, 1) {mustBeNumeric} = 0.05
      Bottom (1, 1) {mustBeNumeric} = 0.05
      Left (1, 1) {mustBeNumeric} = 0.05
      Right (1, 1) {mustBeNumeric} = 0.05
      GridAspectRatio (1, 2) {mustBeNumeric} = [1 1];
   end
   
   properties (Dependent)
      % FigureAspectRatio
      %
      % Multiply this value by the figure height to get the figure width.
      FigureAspectRatio
      
      Size
   end
   
   properties (Dependent, Hidden = true)
      TrueWidth
      TrueHeight
      SubplotWidth
      SubplotHeight
      TrueHSpace
      TrueVSpace
   end
   
   methods
      function self = GridSpec(varargin)
         ip = inputParser;
         ip.addOptional('NumRowsOpt', []);
         ip.addOptional('NumColumnsOpt', []);
         
         paramList = {'NumRows', 'NumColumns', 'VSpace', 'HSpace', 'Top', ...
            'Bottom', 'Left', 'Right'};
         csmu.cellmap(@(p) ip.addParameter(p, []), paramList);
         ip.parse(varargin{:});
         didPassSizeVector = false;
         for iParam = 1:length(paramList)
            paramName = paramList{iParam};
            parserValue = ip.Results.(paramName);
            isValueEmpty = isempty(parserValue);
            switch paramName
               case {'NumRows', 'NumColumns'}
                  if ~isempty(ip.Results.(strcat(paramName, 'Opt')))
                     if ~isValueEmpty
                        L.warn(strcat('Ambiguous setting for %s ', ...
                           'property. Both positional and Name-Value ', ...
                           'arguments are set. Using positional argument.'), ...
                           paramName);
                     end
                     if strcmpi(paramName, 'NumRows')
                        value = ip.Results.(strcat(paramName, 'Opt'));
                        if isvector(value) && length(value) == 2
                           set(self, 'NumRows', value(1));
                           set(self, 'NumColumns', value(2));
                           didPassSizeVector = true;
                           % FIXME - need to use didPassSizeVector to
                           % return a proper error message if a vector is
                           % passed and the optional NumColumns parameter
                           % is supplied. Or do a full refactor checking
                           % within the objects state.
                        else
                           set(self, 'NumRows', value);
                        end
                     else
                        set(self, paramName, ...
                           ip.Results.(strcat(paramName, 'Opt')));
                     end
                  else
                     if ~isValueEmpty
                        set(self, paramName, parserValue)
                     end
                  end
               otherwise
                  if ~isValueEmpty
                     set(self, paramName, parserValue);
                  end                  
            end
         end
      end
      
      function out = get.TrueWidth(self)
         out = 1 - self.Left - self.Right;
      end
      
      function out = get.TrueHeight(self)
         out = 1 - self.Top - self.Bottom;
      end
      
      function out = get.SubplotWidth(self)
         out = self.computeSubWidth(self.TrueWidth, self.NumColumns, ...
            self.HSpace);
      end         
      
      function out = get.SubplotHeight(self)
         out = self.computeSubWidth(self.TrueHeight, self.NumRows, ...
            self.VSpace);
      end
               
      function out = get.TrueHSpace(self)
         out = self.SubplotWidth * self.HSpace;                  
      end
      
      function out = get.TrueVSpace(self)
         out = self.SubplotHeight * self.VSpace;
      end
      
      function axesPosition = subplot(self, rowSpec, colSpec)
         assert(all(rowSpec >= 1) && all(rowSpec <= self.NumRows))
         assert(all(colSpec >= 1) && all(colSpec <= self.NumColumns))
         assert(all(diff(rowSpec) == 1));
         assert(all(diff(colSpec) == 1));
         
         position = csplot.BoxPosition;         
         bottomLeft = self.computeSubplotPosition(rowSpec(end), colSpec(1));
         position.Bottom = bottomLeft.Bottom;
         position.Left = bottomLeft.Left;         
         topRight = self.computeSubplotPosition(rowSpec(1), colSpec(end));
         position.Top = topRight.Top;
         position.Right = topRight.Right;         
         axesPosition = position.AxesPosition;
      end
      
      function position = computeSubplotPosition(self, row, col)
         assert(csmu.isint(row) && row >= 1 && row <= self.NumRows)
         assert(csmu.isint(col) && col >= 1 && col <= self.NumColumns)
         
         position = csplot.BoxPosition;
         position.Left = self.Left ...
            + (col - 1) * (self.TrueHSpace + self.SubplotWidth);
         position.Top = 1 - self.Top ...
            - (row - 1) * (self.TrueVSpace + self.SubplotHeight);
         position.Width = self.SubplotWidth;
         position.Height = self.SubplotHeight;                  
      end
      
      function sref = subsref(self, s)         
         L = csmu.Logger(sprintf('csplot.%s>subsref', mfilename));
         function bool = iscolon(sub)
            bool = isequal(sub, ':') || isequal(sub, ":");
         end
         switch s(1).type
            case '.'
               sref = builtin('subsref', self, s);
               
            case '()'
               nSubs = length(s.subs);
               assert(any(nSubs == [1, 2]), strcat('Invalid or empty', ...
                  ' index passed to GridSpec object.'));
               args = cell(1, 2);
               if nSubs == 1
                  if iscolon(s.subs{1})
                     args{1} = 1:self.end(1);
                     args{2} = 1:self.end(2);
                  else                        
                     if isscalar(s.subs{1})
                        [args{:}] = ind2sub(self.Size, s.subs{1});
                     else
                        failMessage = sprintf(...
                           'Invalid linear vector index ([%s]).', ...
                           num2str(s.subs{1}));
                        
                        [rowSub, colSub] = ind2sub(self.Size, s.subs{1});
                        if all(rowSub(1) == rowSub, 'all')
                           L.assert(...
                              all(colSub(1):colSub(end) == colSub), ...
                              failMessage);
                           args{1} = rowSub(1);
                           args{2} = colSub(1):colSub(end);
                        elseif all(colSub(1) == colSub, 'all')
                           L.assert(...
                              all(rowSub(1):rowSub(end) == rowSub), ...
                              failMessage);
                           args{1} = rowSub(1):rowSub(end);
                           args{2} = colSub(1);
                        else
                           L.error(failMessage);
                        end
                     end
                  end
               else
                  for iSubref = 1:nSubs
                     if iscolon(s.subs{iSubref})
                        args{iSubref} = 1:self.end(iSubref);
                     else
                        args{iSubref} = s.subs{iSubref};
                     end
                  end
               end
               sref = self.subplot(args{:});
               
            case '{}'
               error('GridSpec:subsref', ...
                  'Not a supported subscripted reference')
         end
      end
      
      function out = size(self)
         out = self.Size;
      end
      
      function out = get.Size(self)
         out = [self.NumRows, self.NumColumns];
      end
      
      function widthByHeight = get.FigureAspectRatio(self)         
         height = self.NumRows + ((self.NumRows - 1) * self.VSpace);
         width = self.NumColumns + ((self.NumColumns - 1) * self.HSpace);
         
         height = height / (1 - self.Top - self.Bottom);
         width = width / (1 - self.Left - self.Right);
         
         widthByHeight = width / height;
      end
      
      function ind = end(self, dim, numDims)
         switch dim
            case 1
               ind = self.NumRows;
            case 2
               ind = self.NumColumns;
            otherwise
               error('Unexpected indexing dimensionality with use of end.');
         end
      end
      
   end
   
   methods (Static)
      function sw = computeSubWidth(w, n, alpha)
         sw = w / ((1 + alpha) * n - alpha);
      end
   end
end

