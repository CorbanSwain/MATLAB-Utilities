function filter(self, varargin)

%%% Logger
fcnName = strcat('csmu.Image.', mfilename);
L = csmu.Logger(fcnName);

%% Parsing Inputs
ip = csmu.InputParser.fromSpec({
   {'r', 'FilterName', @csmu.validators.scalarStringLike}
   {'r', 'FilterParams'}
   });
ip.FunctionName = fcnName;
ip.parse(varargin{:});
inputs = ip.Results;

%% Filters
switch lower(inputs.FilterName)
   case 'gaussian'
      if self.NumDims == 2
         self.I = imgaussfilt(self.I, inputs.FilterParams{:});
      elseif self.NumDims == 3
         self.I = imgaussfilt3(self.I, inputs.FilterParams{:});
      else
         L.error(['Gaussian filtering only implemented with an image ' ...
            'having 2 or 3 dimentions.']);
      end
      
   case 'gaussianspeckle'
      ip2 = csmu.InputParser.fromSpec({ ...
         {'p', 'Scale', 1}
         });
      ip2.parse(inputs.FilterParams{:});
      inputs2 = ip2.Results;

      speckleImage = randn(self.Size) * inputs2.Scale;

      if isinteger(self.I)
         ITemp = double(self.I) + (speckleImage * intmax(self.Class));
         self.I = cast(ITemp, self.Class);
      else
         self.I = self.I + speckleImage;
      end      

   otherwise
      L.error('Filter ''%s'' is unimplemented', inputs.FilterName);
end

end