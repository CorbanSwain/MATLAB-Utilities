classdef DynamicShadow < dynamicprops & csmu.Object
   
   properties (Hidden = true)
      DynamicShadowProps
   end
   
   properties (Abstract, Constant)
      ShadowClass
      ShadowClassTag
      ShadowClassExcludeList
   end
   
   properties (Dependent, Hidden = true)
      ShadowClassTagCell
      ShadowClassCell
      ShadowClassExcludeListCell
      AllDynamicShadowPropNames
      ShadowClassRenamedPropNames
      ShadowClassOriginalPropNames
      ShadowClassArgList
   end
   
   methods
      function self = DynamicShadow
         cellfun(@(p) self.addDynamicShadowProp(p), ...
            self.AllDynamicShadowPropNames);
      end
      
      function addDynamicShadowProp(self, propName)         
         dpObject = self.addprop(propName);
         dpObject.NonCopyable = false;
         self.DynamicShadowProps = [self.DynamicShadowProps, dpObject];
      end
      
      function out = get.ShadowClassCell(self)
         out = csmu.tocell(self.ShadowClass);
      end
      
      function out = get.ShadowClassTagCell(self)
         out = csmu.tocell(self.ShadowClassTag);
      end
      
      function out = get.ShadowClassExcludeListCell(self)
         out = csmu.tocell(self.ShadowClassExcludeList, 2);
      end
      
      function out = get.AllDynamicShadowPropNames(self)
         out = vertcat(self.ShadowClassRenamedPropNames{:});
      end
      
      function out = get.ShadowClassRenamedPropNames(self)
         out = csmu.cellmap(@(pcell, t, exclude) ...
            csmu.cellmap(@(p) strcat(t, p), ...
            setdiff(pcell, exclude, 'stable')), ...
            self.ShadowClassOriginalPropNames, self.ShadowClassTagCell, ...
            self.ShadowClassExcludeListCell);
      end
      
      function out = get.ShadowClassOriginalPropNames(self)
        out = csmu.cellmap(@(c) properties(c), self.ShadowClassCell);
      end
      
      function applyShadowClassProps(self, objectHandle)         
         function applyPropsHelper(propList, tag)
            for iProp = 1:length(propList)
               propName = propList{iProp};
               propVal = self.(propName);
               if ~isempty(propVal)
                  validPropName = propName((length(tag) + 1):end);
                  objectHandle.(validPropName) = propVal;
               end
            end
         end
         
         props = self.ShadowClassRenamedPropNames;
         tags = self.ShadowClassTagCell;
         cellfun(@(p, t) applyPropsHelper(p, t), props, tags);
      end
      
      function out = get.ShadowClassArgList(self)
         function argList = makeArgListHelper(propList, tag)
            argList = {};
            for iProp = 1:length(propList)
               propName = propList{iProp};
               propVal = self.([tag, propName]);
               if ~isempty(propVal)
                  validPropName = propName((length(tag) + 1):end);
                  argList = [argList, {validPropName}, {propVal}];
               end
            end
         end
         
         props = self.ShadowClassRenamedPropNames;
         tags = self.ShadowClassTagCell;
         out = csmu.cellmap(@(p, t) makeArgListHelper(p, t), props, tags);
         out = [out{:}];
      end
      
      function [varargout] = subsref(self, S)
         fcnName = strcat('csmu.mixin.', mfilename, '/subsref');
         
         switch S(1).type
            case '{}'
               [varargout{1:nargout}] = builtin('subsref', self, S);
               
            case '()'
               outIndexes = csmu.subsarg2ind(size(self), S(1).subs);
               
               numSubs = numel(outIndexes);
               if isscalar(S)
                  varargout = {[]};
                  for iSub = 1:numSubs
                     varargout{1} = [varargout{1}, self(outIndexes(iSub))];
                  end
               else
                  varargout = cell(size(outIndexes));
                  for iSub = 1:numSubs
                     if nargout
                        varargout{iSub} = subsref(self(outIndexes(iSub)), ...
                           S(2:end));
                     else
                        subsref(self(outIndexes(iSub)), S(2:end));
                     end
                  end
               end
               
            case '.'               
               if any(strcmp(S(1).subs, methods(self)))
                  [varargout{1:nargout}] = builtin('subsref', self, S);
               else                
                  varargout = get(self, S(1).subs);
                  if isscalar(self)
                     varargout = {varargout};
                  end
                  if ~isscalar(S)
                     for iArg = 1:numel(varargout)
                        varargout{iArg} = subsref(varargout{iArg}, S(2:end));
                     end
                  end
               end
               
            otherwise
               L = csmu.Logger(fcnName);
               L.error('Unexpected subscripted reference type.');
         end
      end      
      
   end
      
end