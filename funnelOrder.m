function [Y, I] = funnelOrder(X)
if nargin == 0 
   unittest;
   return;
end

N = length(X);
if N < 3
   Y = X;
   I = 1:N;
else
   ind = zeros(size(X));
   ind(1) = floor(N / 2) + 1;
   ind(2) = ind(1) - 1;
   doAdd = true;
   for i = 3:N
      if doAdd
         k = 1;
      else
         k = -1;
      end
      ind(i) = ind(i - 2) + k;
      doAdd = ~doAdd;
   end
   Y(ind) = X;
   I = zeros(size(X));
   I(ind) = 1:N;
end
end

function unittest
x = rand(1, 5);
[y, I] = utils.funnelOrder(x);
assert(all(sort(x) == sort(y)));
assert(all(x(I) == y));
end