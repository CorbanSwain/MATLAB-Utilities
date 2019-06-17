function filter(self, varargin)

%%% Logger
fcnName = strcat('csmu.Image.', mfilename);
L = csmu.Logger(fcnName);

%% Parsing Inputs
parserSpec = {
   {'r', 'FilterName', @csmu.validators.scalarStringLike}
   {'r', 'FilterParams'}};

ip = csmu.constructInputParser(parserSpec, 'Name', fcnName, 'Args', varargin);
ip = ip.Results;

%% Filters
switch lower(ip.FilterName)
   case 'gaussian'
      if self.NumDims == 2
         self.I = imgaussfilt(self.I, ip.FilterParams{:});
      else
         L.error('Unimplemented');
      end
      
   otherwise
      L.error('Unimplemented');
end

end