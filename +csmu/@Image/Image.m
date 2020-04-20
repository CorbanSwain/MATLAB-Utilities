classdef Image < csmu.mixin.AutoDeal & csmu.Object
   
   properties      
      ImageRef      
      ChannelDim {csmu.validators.mustBeScalarOrEmpty, mustBeInteger} = []
      TimepointDim {csmu.validators.mustBeScalarOrEmpty, mustBeInteger} = []
      FilePath
   end
   
   properties (Hidden = true, Access = protected)
      ProjectionFunction
      XYProjCache = cell(1, 2)
      XZProjCache = cell(1, 2)
      YZProjCache = cell(1, 2)
      ICache = cell(1, 2)
      ChannelsCache = cell(1, 2)
      SliceIdx
   end
   
   properties (Dependent)
      I
      Class                 
      NumDims
      NumElements
     
      Size 
      DataSize
      SingleChannelSize
      SingleTimepointSize  
      
      Channels
      NumChannels
      HasChannels
      
      Timepoints
      NumTimepoints
      HasTimepoints    
   end
   
   properties (Dependent, Hidden = true)
    
      
      NDims
      XYProjection
      XZProjection
      YZProjection
   end
   
   properties (Dependent, Hidden = true, Access = protected)
      ProjectionArgs
   end
   
   properties (Constant, Hidden = true)
      DoCopyOnAutoDeal = true
   end
   
   methods
      function self = Image(varargin)      
         funcName = strcat('csmu.', mfilename);
         L = csmu.Logger(funcName);
         
         if nargin
            try
               sizeCell = csmu.parseSizeArgs(varargin{:});
               isSizeCellPassed = true;
            catch
               isSizeCellPassed = false;
            end
            
            if isSizeCellPassed
               self(sizeCell{:}) = csmu.Image();
               for iElement = 1:(numel(self) - 1)
                  self(iElement) = csmu.Image();
               end
            else
               imageLike = varargin{1};
               otherArgs = varargin(2:end);               
               
               parserSpec = {
                  {'p', 'DoAutoChannelDim', true, 'logicalScalar'}
                  {'p', 'Slice', []}};
               ip = csmu.constructInputParser(parserSpec, 'Name', funcName, ...
                  'Args', otherArgs);
               ip = ip.Results;
               
               switch class(imageLike)
                  case 'csmu.Image'
                     self = copy(imageLike);
                     
                  case {'char', 'string'}
                     self.FilePath = imageLike;
                     
                  otherwise
                     L.assert(isnumeric(imageLike) || islogical(imageLike), ...
                        'Input must be image-like (arr, csmu.Image, or path).');
                     self.I = imageLike;
               end
               self.SliceIdx = ip.Slice;
               
               if ip.DoAutoChannelDim
                  threeDims = find(self.Size == 3);
                  if ~isempty(threeDims) && any(threeDims > 2)
                     threeDims = threeDims(threeDims > 2);
                     if isscalar(threeDims)
                        self.ChannelDim = threeDims;
                        L.warn('Assuming channel dimension to be dim # %d.', ...
                           threeDims);
                     else
                        L.warn(['Ambiguous auto-interpretation for the ', ...
                           'channel dimension, could be any of [%s]. ', ...
                           'Leaving `ChannelDim` property empty because ', ...
                           'of this ambiguity.'], num2str(threeDims));
                     end                     
                  end
               end
            end
         end
      end
      
      filter(self, varargin)
      
      function out = get.I(self)                  
         doLoad = ~isempty(self.FilePath) ...
            && ~isequal(self.ICache{1}, self.FilePath);
         if doLoad
            self.ICache{1} = self.FilePath;
            self.ICache{2} = csmu.loadAnyImage(self.FilePath, ...
               'Slice', self.SliceIdx);
         end
         out = self.ICache{2};
      end
      
      function set.I(self, input)
         self.ICache{2} = input;
      end
      
      function out = get.XYProjection(self)
         if self.NumDims ~= 3
            funcName = strcat('csmu.', mfilename, '/get.XYProjection');
            L = csmu.Logger(funcName);
            L.error('Invalid if image `NumDims` is not 3.')
         end              
         inputArgs = self.ProjectionArgs;         
         if isempty(self.XYProjCache{2}) || ~isequal(self.XYProjCache{1}, ...
               inputArgs)
            self.XYProjCache{1} = inputArgs;
            self.XYProjCache{2} = self.makeProjection(inputArgs{:}, ...
               'ProjectionDimension', 3);  
         end
         out = self.XYProjCache{2}.I;
      end
      
      function out = get.XZProjection(self)
         if self.NumDims ~= 3
            funcName = strcat('csmu.', mfilename, '/get.XZProjection');
            L = csmu.Logger(funcName);
            L.error('Invalid if image `NumDims` is not 3.')
         end
         inputArgs = self.ProjectionArgs;
         if isempty(self.XZProjCache{2}) ...
               || ~isequal(self.XZProjCache{1}, inputArgs)
            self.XZProjCache{1} = inputArgs;
            self.XZProjCache{2} = self.makeProjection(inputArgs{:}, ...
               'ProjectionDimension', 1);
         end
         out = self.XZProjCache{2}.I;
      end
      
      function out = get.YZProjection(self)
         if self.NumDims ~= 3
            funcName = strcat('csmu.', mfilename, '/get.YZProjection');
            L = csmu.Logger(funcName);
            L.error('Invalid if image `NumDims` is not 3.')
         end
         inputArgs = self.ProjectionArgs;
         if isempty(self.YZProjCache{2}) ...
               || ~isequal(self.YZProjCache{1}, inputArgs)
            self.YZProjCache{1} = inputArgs;
            self.YZProjCache{2} = self.makeProjection(inputArgs{:}, ...
               'ProjectionDimension', 2);
         end
         out = self.YZProjCache{2}.I;
      end
      
      function out = get.ProjectionArgs(self)
         out = {self.I};
         if ~isempty(self.ProjectionFunction)
            out = [out, {'ProjectionFunction', self.ProjectionFunction}];
         end
      end
      
      function out = get.DataSize(self)
         if isempty(self.I)
            out = [];
         else
            out = size(self.I);
         end
      end
      
      function out = get.Size(self)
         out = self.DataSize;
         out([self.ChannelDim, self.TimepointDim]) = [];
      end
      
      function out = get.SingleChannelSize(self)
         out = self.DataSize;
         out(self.TimepointDim) = [];
      end
      
      function out = get.SingleTimepointSize(self)
         out = self.DataSize;
         out(self.ChannelDim) = [];
      end
      
      function out = get.NumDims(self)
         out = sum(self.Size > 1);
      end
      
      function out = get.NDims(self)
         funcName  = strcat('csmu.', mfilename, '/get.NDims');
         L = csmu.Logger(funcName);
         L.warn('Property `NDims` is deprecated; use `NumDims` instead.');
         out = self.NumDims;
      end
      
      function out = get.NumChannels(self)         
         out = self.DataSize(self.ChannelDim);
      end
      
      function out = get.HasChannels(self)
         out = ~isempty(self.ChannelDim);
      end
      
      function out = get.Channels(self)
         inputArgs = {self.I, self.ChannelDim};
         if isempty(self.ChannelsCache{2}) ...
               || ~isequal(self.ChannelsCache{1}, inputArgs)
            self.ChannelsCache{1} = inputArgs;
            self.ChannelsCache{2} = self.unstackImage(inputArgs{:});
         end
         out = copy(self.ChannelsCache{2});
      end
      
      function set.Channels(self, varargin)
         funcName = strcat('csmu.', mfilename, '.set.Channels');
         L = csmu.Logger(funcName);
         L.assert(~isempty(self.ChannelDim), ['`ChannelDim` property must ', ...
            'not be empty if attempting to set channel property']);
         if length(varargin) == 1 && iscell(varargin{1})
            varargin = varargin{1};
         end
         newIm = self.stackImage(self.ChannelDim, varargin{:});
         if ~isempty(self.I) 
            if newIm.Size ~= self.Size
               L.warn('Image dimensions changed when applying channels ', ...
                  '([%s] -> [%s]).', num2str(self.Size), num2str(newIm.Size));
            elseif newIm.NumChannels ~= self.NumChannels
               L.warn(['Number of channels changed when applying channels ', ...
                  '(%d -> %d).'], self.NumChannels, newIm.NumChannels);
            end
         end
         self.I = newIm.I;            
      end
      
      function out = get.NumTimepoints(self)
         out = self.DataSize(self.TimepointDim);
      end
      
      function out = get.HasTimepoints(self)
         out = ~isempty(self.TimepointDim);
      end
      
      function out = get.Timepoints(self)
         
      end
      
      function out = get.NumElements(self)
         out = numel(self.I);
      end
      
      function out = get.Class(self)
         out = class(self.I);
      end
      
      function reshape(self, varargin)
         if self.HasChannels
            self.Channels = arrayfun(@(im) im.reshape(varargin{:}), ...
               self.Channels);
         else            
            self.I = reshape(self.I, varargin{:});
         end
      end
      
   end
   
   methods (Static)
      function projImage = makeProjection(V, varargin)
        ip = inputParser;
        ip.addParameter('ProjectionDimension', 3, ...
           @(x) isnumeric(x) && isscalar(x));
        ip.addParameter('ProjectionFunction', ...
           @(varargin) csmu.maxProject(varargin{:}), ...
           @(x) isa(x, 'function_handle'));
        ip.addParameter('ColorWeight', []);
        ip.parse(varargin{:});
        ip = ip.Results;
        
        projDim = ip.ProjectionDimension;
        projFcn = ip.ProjectionFunction;
        colorWeight = ip.ColorWeight;
        
        projImage = projFcn(V, projDim, 'ColorWeight', colorWeight);
        if projDim == 1
           projImage = permute(projImage, [2 1]);
        end
        projImage = csmu.Image(projImage);
      end
      
      function channelArray = unstackImageOld(I, channelDim)
         nChannels = size(I, channelDim);
         dimDist = num2cell(size(I));
         dimDist{channelDim} = ones(1, nChannels);
         channels = squeeze(mat2cell(I, dimDist{:}));
         newSize = size(I);
         newSize(channelDim) = [];
         channels = csmu.cellmap(@(im) reshape(im, newSize), channels);
         channels = csmu.cellmap(@(im) csmu.Image(im), channels);
         channelArray = cat(1, channels{:});
         channelArray.subsasgn(struct('type', '.', 'subs', 'ChannelDim'), []);
      end
      
      function imageArray = unstackImage(stackDim, stackType, imageData)
         %   Inputs
         %      - splitDim: (1, 1) {numeric, integer,  > 0}
         %      - splitType: {scalarStringLike}
         %      - imageData: {numeric}
         %
         %   Outputs
         %      - imageArray: (1, :) csmu.Image
                 
         oldSize = size(imageData);
         newSize = oldSize;
         newSize(stackDim) = [];
         
         imageArray = csmu.cat(...
            1, ...
            csmu.cellmap(@(im) csmu.Image(reshape(im, newSize)), ...
            csmu.uncat(stackDim, imageData)));
         
         stackType = csmu.ImageStackType(stackType);
         imageArray.subsasgn(...
            struct('type', '.', 'subs', stackType.DimLabel), ...
            []);
      end                
      
      function I = stackImageOld(stackDim, varargin)
         if length(varargin) == 1 && isa(varargin{1}, 'csmu.Image')
            channels = copy(varargin{1});            
         else            
            channels = csmu.cellmap(@(im) csmu.Image(im), varargin); 
            channels = cat(1, channels{:});
         end         
         channels.subsasgn(struct('type', '.', 'subs', 'ChannelDim'), []);
         nChannels = length(channels);

         if nChannels == 0
            I = [];
            return
         end
         
         originalNumDims = channels(1).NumDims;                  
         newNumDims = max(originalNumDims + 1, stackDim);                  
         originalSize = [channels(1).Size, ...
            ones(1, newNumDims - originalNumDims - 1)];
         newSize = ones(1, newNumDims);
         newSize((1:newNumDims) ~= stackDim) = originalSize;
         arrayfun(@(im) im.reshape(newSize), channels);
         I = csmu.Image.imcat(stackDim, channels);
         I.ChannelDim = stackDim;
      end
      
      function I = stackImage(stackDim, stackType
      
      function outputImage = imcat(stackDimension, varargin)
         if length(varargin) == 1 && isa(varargin{1}, 'csmu.Image')
            stack = varargin{1};
         else
            stack = cellfun(@(im) csmu.Image(im), varargin);
         end
         
         if all(arrayfun(@(im) im.HasChannels, stack))
            channelDims = arrayfun(@(im) im.ChannelDim, stack);            
            if all(channelDims == channelDims(1))
               channelDim = channelDims(1);
            else
               channelDim = [];
            end
         else
            channelDim = [];
         end
         
         stack = arrayfun(@(im) im.I, stack, 'UniformOutput', false);         
         outputImage = csmu.Image(cat(stackDimension, stack{:}), ...
            'DoAutoChannelDim', false);                
         outputImage.ChannelDim = channelDim;
      end
   end
   
end
      