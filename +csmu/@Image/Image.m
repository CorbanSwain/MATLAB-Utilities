classdef Image < csmu.Object
   
   properties
      I {mustBeNumericOrLogical}
      ImageRef
      ProjectionFunction
   end
   
   properties (Dependent)
      XYProjection
      XZProjection
      YZProjection
   end
   
   properties (Dependent, Hidden = true, Access = protected)
      ProjectionArgs
   end
   
   methods
      function self = Image(varargin)
         L = csmu.Logger(strcat('csmu.', mfilename));
         if nargin
            narginchk(0, 1);
            switch class(varargin{1})
               case 'csmu.Image'
                  self = copy(varargin{1});
                  
               case {'char', 'string'}
                  self.I = csmu.loadAnyImage(varargin{1});
                  
               otherwise
                  L.assert(isnumeric(varargin{1}) || islogical(varargin{1}), ...
                     'Input must be a numeric or logical array.');
                  self.I = varargin{1};
            end
         end
      end
      
      function out = get.XYProjection(self)
         persistent inputCache
         persistent outputCache         
         inputArgs = self.ProjectionArgs;         
         if isempty(outputCache) || ~isequal(inputCache, inputArgs)
            inputCache = inputArgs;
            outputCache = self.makeProjection(inputArgs{:}, ...
               'ProjectionDimension', 3);  
         end
         out = outputCache.I;
      end
      
      function out = get.XZProjection(self)
         persistent inputCache
         persistent outputCache
         inputArgs = self.ProjectionArgs;
         if isempty(outputCache) || ~isequal(inputCache, inputArgs)
            inputCache = inputArgs;
            outputCache = self.makeProjection(inputArgs{:}, ...
               'ProjectionDimension', 1);
         end
         out = outputCache.I;
      end
      
      function out = get.YZProjection(self)
         persistent inputCache
         persistent outputCache
         inputArgs = self.ProjectionArgs;
         if isempty(outputCache) || ~isequal(inputCache, inputArgs)
            inputCache = inputArgs;
            outputCache = self.makeProjection(inputArgs{:}, ...
               'ProjectionDimension', 2);
         end
         out = outputCache.I;
      end
      
      function out = get.ProjectionArgs(self)
         out = {self.I};
         if ~isempty(self.ProjectionFunction)
            out = [out, {'ProjectionFunction', self.ProjectionFunction}];
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
   end
   
end
      