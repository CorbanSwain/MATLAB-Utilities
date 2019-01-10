function [I, varargout] = prcsaturate(I, varargin)
% Saturates a percentage of an image with the given gain.

ip = inputParser;
ip.addOptional('p', 0, @(x) (x >= 0) && (x <= 100));
ip.addOptional('gain', 1, @(x) x > 0);
ip.addOptional('fullscale', false, @islogical);
ip.parse(varargin{:});
p = ip.Results.p;
gain = ip.Results.gain;
doFullScale = ip.Results.fullscale;


if doFullScale
   I = csmu.fullscaleim(I); % min(I) is 0 and max(I) is 1
   if p == 0
      I = I * gain;
   elseif p == 100
      I(:) = Inf; 
   else
      pctCalc = prctile(I(:), 100 - p);
      if pctCalc == 0
         warning('The given percent value is too large, clipping all pixels.');
         pctCalc = min(I(I > 0));
      end
      I = I / pctCalc * gain;
   end
   % no factor to return since the image was shifted
else
   if p == 0
      f = 1 / max(I(:)) * gain;
   elseif p == 100
      f = 1 / min(I(:)) * gain;
   else
      f = 1 / prctile(I(:), 100 - p) * gain;
   end
   
   I = I * f;
      
   switch nargout
      case 1
      case 2
         varargout{1} = f;
   end
end

