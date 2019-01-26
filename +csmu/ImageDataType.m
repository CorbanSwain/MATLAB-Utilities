classdef ImageDataType
   enumeration
      uint8 (8)
      uint16 (16)
      uint32 (32)
      uint64 (64)
      
      int8 (8)
      int16 (16)
      int32 (32)
      int64 (64)
      
      single (32)
      double (64)
      
      logical (1)
   end
   
   properties
      NumBits
      NumberClassString
   end
   
   properties (Dependent)
      TiffSampleFormat
   end
   
   properties (Constant)
      uintTypes = {csmu.ImageDataType.uint8, ...
         csmu.ImageDataType.uint16, ...
         csmu.ImageDataType.uint32, ...
         csmu.ImageDataType.uint64, ...
         csmu.ImageDataType.logical}
      
      intTypes= {csmu.ImageDataType.int8, ...
         csmu.ImageDataType.int16, ...
         csmu.ImageDataType.int32, ...
         csmu.ImageDataType.int64}
      
      floatTypes = {csmu.ImageDataType.single, ...
         csmu.ImageDataType.double}      
   end
   
   methods
      function self = ImageDataType(numBits)
         self.NumBits = numBits;
      end
      
      function out = get.TiffSampleFormat(self)
         switch self
            case csmu.ImageDataType.uintTypes
               out = Tiff.SampleFormat.UInt;
               
            case csmu.ImageDataType.intTypes
               out = Tiff.SampleFormat.Int;
               
            case csmu.ImageDataType.floatTypes
               out = Tiff.SampleFormat.IEEEFP;
         end
      end
      
      function out = get.NumberClassString(self)
         out = char(self);
      end
   end
   
   methods (Static)
      function bits = var2bits(var)
         idt = csmu.ImageDataType(class(var));
         bits = idt.NumBits;
      end
      
      function cls = bits2class(varargin)
         idt = csmu.ImageDataType.fromNumBits(varargin{:});
         cls = idt.NumberClassString;
      end
      
      function idt = fromNumBits(varargin)
         ip = inputParser;
         ip.addRequired('NumBits', @(x) any(x == [1, 8, 16, 32, 64]))
         ip.addOptional('PreferredType', [], @(x) any(strcmpi(x, ...
            {'uint', 'int', 'float', 'logical'})));
         ip.parse(varargin{:});
         numBits = ip.Results.NumBits;
         preferredType = ip.Results.PreferredType;
         if isempty(preferredType)
            if numBits == 1 
               preferredType = 'logical';
            else
               preferredType = 'uint';
            end
         end
         preferredType = lower(preferredType);
         switch preferredType
            case {'uint', 'int'}
               assert(numBits > 1, ['NumBits cannot be 1 if ''uint'' or ', ...
                  '''int'' is the preferred type.']);
               idt = sprintf('%s%d', preferredType, numBits);
            case 'logical'
               assert(numBits == 1, ['NumBits must be 1 if ''logical''', ...
                  'is the preferred type.']);
               idt = 'logical';
            case 'float'
               assert(any(numBits == [32, 64]), ['NumBits must be 32 or ', ...
                  'if ''float'' is the preferred type.']);
               if numBits == 32
                  idt = 'single';
               else
                  idt = 'double';
               end
         end
         idt = csmu.ImageDataType(idt);
      end
   end
end