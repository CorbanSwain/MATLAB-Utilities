classdef AutoDeal < handle
   
   properties (Abstract, Constant, Hidden = true)
      DoCopyOnAutoDeal (1, 1) logical
   end
   
   methods
      function self = subsasgn(self, S, varargin)
         L = csmu.Logger(strcat('+csmu.', mfilename, '/subsasgn'));         
         
         switch S(1).type
            case '{}'
               self = builtin('subsasgn', self, S, varargin{:});
               
            case '()'
               indexes = csmu.subsarg2ind(size(self), S(1).subs);
               numIdxs = numel(indexes);
               if ~isscalar(varargin)
                  L.assert(length(varargin) == numIdxs);
               end
               for iSub = 1:numIdxs
                  idx = indexes(iSub);
                  if isscalar(varargin)
                     B = varargin{1};
                  else
                     B = varargin{iSub};
                  end
                  if isscalar(S)
                     if self.DoCopyOnAutoDeal
                        self(idx) = copy(B);
                     else
                        self(idx) = B;
                     end
                  else
                     self(idx) = subsasgn(self(idx), S(2:end), B);
                  end
               end
               
            case '.'
               if isscalar(self)
                  propertyName = S(1).subs;
                  if isscalar(S)
                     % FIXME - compare lengths as well
                     set(self, propertyName, varargin{:});
                  else
                     propertyValue = subsref(self, ...
                        struct('type', {'.'}, 'subs', {propertyName}));
                     set(self, propertyName, ...
                        subsasgn(propertyValue, S(2:end), varargin{:}));
                  end
               else
                  S = [struct('type', '()', 'subs', ':'), S];
                  self = subsasgn(self, S, varargin{:});                  
               end
               
            otherwise
               L.error('Unexpected subscripted reference type');
         end         
      end
      
   end
   
end