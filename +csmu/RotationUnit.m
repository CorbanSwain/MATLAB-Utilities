classdef RotationUnit

enumeration

   DEGREE
   RADIAN

end
   
methods
   
   function y = toRadians(self, x)
      switch self
         case csmu.RotationUnit.DEGREE
            y = deg2rad(x);            

         case csmu.RotationUnit.RADIAN
            y = x;
      end
   end

   function y = toDegrees(self, x)
      switch self
         case csmu.RotationUnit.DEGREE
            y = x;

         case csmu.RotationUnit.RADIAN
            y = rad2deg(x);
      end
   end

end

end