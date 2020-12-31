function B = changeView(A, RA, RB, fillValue)
L = csmu.Logger('csmu.changeView');
L.assert(all(RA.ImageSize == size(A)), ...
   ['size(A) not equal to RA.ImageSize.\n\tsize(A) = [%s], RA.ImageSize =', ...
   ' [%s]'], num2str(size(A)), num2str(RA.ImageSize));
if csmu.refeq(RA, RB)
   B = A;
else
   if length(RA.ImageSize) == 3
      prepad = [RA.YWorldLimits(1) - RB.YWorldLimits(1), ...
         RA.XWorldLimits(1) - RB.XWorldLimits(1), ...
         RA.ZWorldLimits(1) - RB.ZWorldLimits(1)];
      prepad = round(prepad - eps(prepad));
      postpad = -1 * [RA.YWorldLimits(2) - RB.YWorldLimits(2), ...
         RA.XWorldLimits(2) - RB.XWorldLimits(2), ...
         RA.ZWorldLimits(2) - RB.ZWorldLimits(2)];
      postpad = round(postpad + eps(postpad));
      overlapsize = min( ...
         RA.ImageSize - (subplus(-prepad) + subplus(-postpad)), ...
         RB.ImageSize - (subplus(prepad) + subplus(postpad)));
      Bidxstart = max([1 1 1], prepad + 1);
      Bidxend = Bidxstart + overlapsize - 1;
      Aidxstart = max([1 1 1], -prepad + 1);
      Aidxend = Aidxstart + overlapsize - 1;
      bsel = {Bidxstart(1):Bidxend(1), ...
         Bidxstart(2):Bidxend(2), ...
         Bidxstart(3):Bidxend(3)};
      asel = {Aidxstart(1):Aidxend(1), ...
         Aidxstart(2):Aidxend(2), ...
         Aidxstart(3):Aidxend(3)};
      if nargin == 4
         B = ones(RB.ImageSize, class(A)) .* fillValue;
      else
         B = zeros(RB.ImageSize, class(A));
      end
      B(bsel{:}) = A(asel{:});
   else
      prepad = [RA.YWorldLimits(1) - RB.YWorldLimits(1), ...
         RA.XWorldLimits(1) - RB.XWorldLimits(1)];
      prepad = round(prepad - eps(prepad));
      postpad = -1 * [RA.YWorldLimits(2) - RB.YWorldLimits(2), ...
         RA.XWorldLimits(2) - RB.XWorldLimits(2)];
      postpad = round(postpad + eps(postpad));
      overlapsize = min( ...
         RA.ImageSize - (subplus(-prepad) + subplus(-postpad)), ...
         RB.ImageSize - (subplus(prepad) + subplus(postpad)));
      Bidxstart = max([1 1], prepad + 1);
      Bidxend = Bidxstart + overlapsize - 1;
      Aidxstart = max([1 1], -prepad + 1);
      Aidxend = Aidxstart + overlapsize - 1;
      bsel = {Bidxstart(1):Bidxend(1), ...
         Bidxstart(2):Bidxend(2)};
      asel = {Aidxstart(1):Aidxend(1), ...
         Aidxstart(2):Aidxend(2)};
      if nargin == 4
         B = ones(RB.ImageSize, class(A)) .* fillValue;
      else
         B = zeros(RB.ImageSize, class(A));
      end
      B(bsel{:}) = A(asel{:});
   end
end
