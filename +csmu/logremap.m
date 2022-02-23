function [varargout] = logremap(x, minClip, maxClip, nvInputs)

arguments
   x
   minClip double {mustBeScalarOrEmpty} = []
   maxClip double {mustBeScalarOrEmpty} = []
   nvInputs.DoInvert (1, 1) logical = false
   nvInputs.Base (1, 1) double = exp(1)
end

base = nvInputs.Base;

if nvInputs.DoInvert
   y = unmap(x, base, minClip, maxClip);
   varargout = {y};
   return
end

logn = @(x) log(x) / log(base);

HALF_VAL = 0.5;
LOG_HALF = logn(HALF_VAL);
MIN_DELTA = 1;

lowFilt = x <= HALF_VAL;
xLow = x(lowFilt);
highFilt = ~lowFilt;
xHigh = x(highFilt);

   function [bScaled, clipVal] = remapHelper(a, clipVal)
      b = logn(a);
      if isempty(clipVal)
         finiteB = b(isfinite(b));
         if isempty(finiteB)
            minB = -MIN_DELTA;         
         else
            minB = min(finiteB, [], 'all') - MIN_DELTA;
         end
         
         clipVal = base .^ minB;
      else
         minB = logn(clipVal);
      end
      
      b(b < minB) = minB;
      bScaled = (b - minB) / (LOG_HALF - minB) / 2;
   end

[yLow, minClip] = remapHelper(xLow, minClip);
[yHigh, maxClip] = remapHelper(1 - xHigh, 1 - maxClip);
yHigh = 1 - yHigh;
maxClip = 1 - maxClip;

y = zeros(size(x), 'like', x);
y(lowFilt) = yLow;
y(highFilt) = yHigh;

switch nargout
   case 3
      varargout = {y, minClip, maxClip};

   otherwise
      varargout = {y};
end
end


function  x = unmap(y, base, minClip, maxClip)
arguments
   y
   base
   minClip
   maxClip
end

if isempty(minClip) || isempty(maxClip)
   fcnName = strcat('csmu.', mfilename, '>unmap');
   L = csmu.Logger(fcnName);
   L.error(['Values for `minClip` and `maxClip` must be passed when ' ...
      'DoInvert argument is set to true.'])
end

HALF_VAL = 0.5;
logn = @(x) log(x) / log(base);
LOG_HALF = logn(HALF_VAL);

lowFilt = y <= HALF_VAL;
yLow = y(lowFilt);
highFilt = ~lowFilt;
yHigh = y(highFilt);

   function a = unmapHelper(bScaled, clipVal)
      minB = logn(clipVal);
      b = (bScaled * 2 * (LOG_HALF - minB)) + minB;
      a = base .^ b;
   end

xLow = unmapHelper(yLow, minClip);
xHigh = 1 - unmapHelper(1 - yHigh, 1 - maxClip);

x = zeros(size(y), 'like', y);
x(lowFilt) = xLow;
x(highFilt) = xHigh;
end
