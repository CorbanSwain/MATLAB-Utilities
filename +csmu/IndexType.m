classdef IndexType   
   properties
      text
   end
   
   methods
      function self = IndexType(text)
         self.text = text;
      end
      
      function out = isequal(a, b)
         out = eq(a, b);
      end
      
      function out = eq(a, b)
          if ~isa(a, 'csmu.IndexType')
            try
               a = csmu.IndexType(lower(char(a)));
            catch
               out = false;
               return;
            end
         end
         
         if ~isa(b, 'csmu.IndexType')
            try
               b = csmu.IndexType(lower(b));
            catch
               out = false;
               return;
            end
         end
         out = strcmp(a.text, b.text);
      end
   end
   
   enumeration
      SCALAR ('scalar')
      VECTOR ('vector')
      ARRAY ('array')
      POINT_LIST ('point_list')
      INDEX ('index')
   end
end