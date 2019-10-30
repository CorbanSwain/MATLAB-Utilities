classdef BoxPosition < matlab.mixin.Copyable
   properties
      Left
      Bottom
      Width
      Height                  
   end
   
   properties (Hidden = true)
      % FIXME - behavior can still be a bit unpredictable with the order of
      % setting different properties
      TempTop
      TempRight
   end
   
   properties (Dependent)
      Top
      Right
      AxesPosition
   end
   
   methods 
      function self = BoxPosition(varargin)
         if nargin            
            assert(nargin == 1);
            [self.Left, self.Bottom, self.Width, self.Height] ...
               = csmu.cell2csl(num2cell(varargin{1}));
         end
      end
      
      function out = get.AxesPosition(self)
         out = [self.Left, self.Bottom, self.Width, self.Height];
      end
      
      function set.Bottom(self, val)
         self.Bottom = val;
         self.clearTempTop;
      end
      
      function set.Left(self, val)
         self.Left = val;
         self.clearTempRight;
      end
      
      function set.Width(self, val)
         self.Width = val;
         self.clearTempRight;
      end
      
      function set.Height(self, val)
         self.Height = val;
         self.clearTempTop;
      end
      
      function clearTempTop(self)
         if ~isempty(self.TempTop)
            if isempty(self.Bottom)
               self.Bottom = self.TempTop - self.Height;
            elseif isempty(self.Height)
               self.Height = self.TempTop - self.Bottom;
            end
            self.TempTop = [];
         end
      end
      
      function clearTempRight(self)
         if ~isempty(self.TempRight)
            if isempty(self.Left)
               self.Left = self.TempRight - self.Width;
            elseif isempty(self.Width)
               self.Width = self.TempRight - self.Left;
            end
            self.TempRight = [];
         end
      end      
      
      function out = get.Top(self)
         if ~isempty(self.TempTop)
            out = self.TempTop;
         else
            out = self.Bottom + self.Height;
         end
      end
      
      function out = get.Right(self)
         if ~isempty(self.TempRight)
            out = self.TempRight;
         else
            out = self.Left + self.Width;
         end
      end
      
      function set.Top(self, val)
         if isempty(self.Bottom)
            if isempty(self.Height)
               self.TempTop = val;
            else
               self.Bottom = val - self.Height;
            end
         else
            self.Height = val - self.Bottom;
         end
      end
      
      function set.Right(self, val)
         if isempty(self.Left)
            if isempty(self.Width)
               self.TempRight = val;
            else
               self.Left = val - self.Width;
            end
         else
            self.Width = val - self.Left;
         end
      end
   end
   
end