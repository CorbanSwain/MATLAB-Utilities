function out = tocell(val, varargin)
if nargin == 0
   unittest;
   return
end

ip = inputParser;
ip.addOptional('depth', 1, @(x) x >= 0 && csmu.isint(x));
ip.parse(varargin{:});
depth = ip.Results.depth;

out = val;
for i = 1:depth
   if ~iscell(cellunwrap(out, i - 1))
      out = {out};
   end
end
end

function out = cellunwrap(val, depth)
out = val;
for i = 1:depth
   out = out{1};
end
end

function unittest
L = csmu.Logger('csmu.tocell>unittest');
L.info('Beginning unittests ...');
L.assert(isequal(10, csmu.tocell(10, 0)));
L.assert(isequal({10}, csmu.tocell(10, 1)));

a = {{1}, {2}};
L.assert(isequal(a, csmu.tocell(a, 2)));

bIn = 3;
bOut = {{{{bIn}}}};
L.assert(isequal(bOut, csmu.tocell(bIn, 4)));
L.info('All tests passed.');
end