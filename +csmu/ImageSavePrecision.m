classdef ImageSavePrecision

enumeration

   SINGLE (-32)
   DOUBLE (-64)
   UINT8  (8)
   UINT10 (10)
   UINT11 (11)
   UINT12 (12)
   UINT13 (13)
   UINT14 (14)
   UINT15 (15)
   UINT16 (16)
   UINT24 (24)
   UINT32 (32)
   UINT64 (64)

end


properties (GetAccess = 'protected')

   HashValue (1, 1) double

end


properties (Dependent)
  
   ClassName
   MaximumValue
   IsInteger
   IsFloat

end

methods

   function self = ImageSavePrecision(hashVal)
      self.HashValue = hashVal;
   end

   function out = get.IsInteger(self)
      out = self.HashValue > 0;
   end

   function out = get.IsFloat(self)
      out = self.HashValue < 0;
   end

   function out = get.ClassName(self)
      switch self.HashValue
         case -64, out = 'double';
         case -32, out = 'single';
         case 8,   out = 'uint8';
         case {10, 11, 12, 13, 14, 15, 16},  out = 'uint16';
         case {24, 32}, out = 'uint32';
         case 64, out = 'uint64';
         
         otherwise
            L = csmu.Logger(...
               strcat('csmu.', mfilename(), '.get.ClassName'));
            L.warn('Unexpected value passed for enumeration: %s.', ...
               self);
      end
   end

   function out = get.MaximumValue(self)
      switch self.HashValue
         case {-64, -32}, out = 1;
         case {8, 16, 32, 64}, out = intmax(self.ClassName);
         case {10, 11, 12, 13, 14, 15, 24}
            out = (2 ^ self.HashValue) - 1;
         
         otherwise
            L = csmu.Logger(...
               strcat('csmu.', mfilename(), '.get.MaximumValue'));
            L.error('Unexpected value passed for enumeration: %s.', ...
               self);
      end

      out = double(out);         
   end

   function IPrime = float2image(self, I)
      arguments
         self (1, 1) csmu.ImageSavePrecision
         I {mustBeFloat}
      end

      inputClass = class(I);
      h_intmax = cast(self.MaximumValue, inputClass);
      h_zero = cast(0, inputClass);
      IPrime = self.cast(csmu.bound(I * h_intmax, h_zero, h_intmax));     
   end

   function y = cast(self, x)
      y = cast(x, self.ClassName);
   end

end

methods (Static)

   function IPrime = image2image(I, nvArgs)
      arguments
         I {mustBeNumeric}
         nvArgs.InputType (1, 1) csmu.ImageSavePrecision
         nvArgs.OutputType (1, 1) csmu.ImageSavePrecision
      end

      DEFAULT_FLOAT = 'double';

      L = csmu.Logger(strcat('csmu.', mfilename(), '.image2image'));
      L.assert(isa(I, class(nvArgs.InputType.ClassName)), ['Input image ' ...
         'must have class of the input type, %s; got %s.'], ...
         nvArgs.InputType.ClassName, class(I));

      if nvArgs.InputType.IsFloat
         IPrime = nvArgs.OutputType.float2image(I);
      elseif nvArgs.InputType.IsInteger
         if nvArgs.OutputType.IsFloat
            tempFloatClass = nvArgs.OutputType.ClassName;
         else
            tempFloatClass = DEFAULT_FLOAT;
         end
         
         maxVal_float = cast(nvArgs.InputType.MaximumValue, tempFloatClass);
         IPrime = cast(I, tempFloatClass);
         IPrime = IPrime / maxVal_float;
         IPrime = nvArgs.OutputType.float2image(IPrime);
      else
         L.error(['Unexpected case reached, input type is neither integer' ...
            'or float.'])
      end
   end

end

end