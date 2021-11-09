classdef InputParser < inputParser
   
   properties (SetAccess = 'protected')
      RequiredParamNames = {}
   end
   
   properties (Dependent)
      MissingRequiredParams
      DoKeepUnmatched
   end
   
   methods
      
      function addRequiredParameter(self, name, varargin)
         self.addParameter(name, [], varargin{:});
         self.addRequiredParameterName(name);
      end
      
      function parse(self, varargin)
         
         % not using strcat for speed
         fcnName = ['csmu.', mfilename, '.parse'];         
         
         try
            parse@inputParser(self, varargin{:});
         catch ME
            L = csmu.Logger(fcnName);
            L.logException(csmu.LogLevel.ERROR, ME);
            ME.throwAsCaller();
         end
         
         if ~isempty(self.MissingRequiredParams)
            errId = 'CSMU:InputParser:MissingParams';
            errMsg = sprintf(strcat('The following required parameters', ...
               ' were not provided: ''%s''.'), ...
               csmu.cell2csl(join(self.MissingRequiredParams, ''', ''')));
            ME = MException(errId, errMsg);
            L = csmu.Logger(fcnName);
            L.logException(csmu.LogLevel.ERROR, ME);
            ME.throwAsCaller();
         end
      end
      
      function output = get.MissingRequiredParams(self)
         output = {};
         for iReqParam = 1:length(self.RequiredParamNames)
            reqParam = self.RequiredParamNames{iReqParam};
            if any(strcmp(reqParam, self.UsingDefaults))
               output = [output, {reqParam}];
            end
         end
      end
      
      function set.DoKeepUnmatched(self, input)
         self.KeepUnmatched = input;
      end
      
      function output = get.DoKeepUnmatched(self)
         output = self.KeepUnmatched;
      end
      
   end
   
   methods (Access = 'private')
      
      function addRequiredParameterName(self, name)
         self.RequiredParamNames = [
            self.RequiredParamNames, {char(string(name))}];
      end
      
   end
   
   methods (Static)
      
      function outputInputParser = fromSpec(varargin)
                  
         % not using strcat for speed
         fcnName = ['csmu.',  mfilename, '.fromSpec'];
         
         ip = inputParser();
         ip.addRequired('SpecList');
         ip.addParameter(...
            'DoWithholdReqParamDefaultArg', ...
            true, ...
            @csmu.validators.logicalScalar);
         
         ip.parse(varargin{:});
         inputs = ip.Results;
         
         requiredFlags = {'r', 'required', 'addrequired'};
         optionalFlags = {'o', 'optional', 'addoptional'};
         parameterFlags = {'p', 'param', 'parameter', 'addparameter'};
         reqParamFlags = {'rp', 'reqparam', 'addrequiredparameter'};
         
         outputInputParser = csmu.InputParser();
         
         didWarn = false;
         
         for iSpec = 1:length(inputs.SpecList)
            spec = inputs.SpecList{iSpec};
            inputTypeFlag = lower(spec{1});
            args = spec(2:end);
            
            switch inputTypeFlag
               case requiredFlags
                  validatorIdx = 2;
                  
               case [optionalFlags, parameterFlags]
                  validatorIdx = 3;
                  
               case reqParamFlags
                  validatorIdx = 2;
                  if ~inputs.DoWithholdReqParamDefaultArg
                     if ~didWarn
                        didWarn = true;
                        if ~exist('L', 'var')
                           L = csmu.Logger(fcnName);
                        end
                        L.warn(strcat('Depricated behavior. Remove default', ...
                           ' arguments from all required params (rp) in', ...
                           ' input spec list and set the', ...
                           ' `DoWithholdReqParamDefaultArg` parameter to', ...
                           ' true when calling `constructInputParser(...)`.'));
                     end
                     
                     args = [args(1), args(3:end)];
                  end
                  
               otherwise
                  if ~exist('L', 'var')
                     L = csmu.Logger(fcnName);
                  end
                  errId = 'CSMU:InputParser:BadSpec';
                  errMsg = sprintf(strcat('Encountered an unexpected', ...
                     ' input type flag (%s) while building a', ...
                     ' csmu.InputParser object from a spec list.'), ...
                     inputTypeFlag);
                  ME = MException(errId, errMsg);
                  L.logException(csmu.LogLevel.ERROR, ME);
                  ME.throw();
            end
            
            if length(args) == validatorIdx
               % using the `eval` function where possible to make parsing error 
               % messages more descriptive when the message quotes a 
               % function handle.
               if csmu.validators.stringLike(args{validatorIdx})
                  % not using sprintf and strcat for speed
                  eval(['args{validatorIdx} = @csmu.validators.', ...
                     args{validatorIdx}, ';']);
                  
               elseif iscell(args{validatorIdx})                                    
                  try 
                     cellStr = csmu.cell2str(args{validatorIdx});
                     validCellStr = isequal(args{validatorIdx}, eval(cellStr));
                  catch
                     validCellStr = false;
                  end
                  
                  if validCellStr
                     % not using sprintf and strcat for speed
                     eval(['args{validatorIdx} = @(x) csmu.validators.', ...
                        'member(x, ', cellStr,');']);
                  else
                     args{validatorIdx} = ...
                        @(x) csmu.validators.member(x, args{validatorIdx});
                  end
                
               end
            end
            
            switch inputTypeFlag
               case requiredFlags
                  outputInputParser.addRequired(args{:});
                  
               case optionalFlags
                  outputInputParser.addOptional(args{:});
                  
               case parameterFlags
                  outputInputParser.addParameter(args{:});
                  
               case reqParamFlags
                  outputInputParser.addRequiredParameter(args{:});
            end
         end         
      end
      
   end
   
end