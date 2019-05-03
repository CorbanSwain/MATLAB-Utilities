classdef Object < matlab.mixin.Copyable & matlab.mixin.SetGet
   methods                  
      function outStruct = struct(self)
         function val = doShowProp(p)
            val = all([ ...
               p.Abstract == false, ...
               strcmpi(p.GetAccess, 'public'), ...
               p.Hidden == false]);
         end         
         mc = metaclass(self);
         props = mc.Properties;
         outStruct = struct;
         for iProp = 1:length(props)
            prop = props{iProp};
            if doShowProp(prop)
               outStruct.(prop.Name) = self.(prop.Name);
            end
         end
      end
   end
end