function rout = angsimplify(rin)
L = csmu.Logger('csmu.angsimplify');
L.assert(isvector(rin) && length(rin) == 3);

rin = mat2cell(deg2rad(rin(:)), [1 1 1]);

q = angle2quat(rin{:}, 'XYZ');
axang = quat2axang(q);
axang(4) = mod(axang(4), 2 * pi);
if abs(axang(4) - (pi)) < eps
   axangSign = sign(axang(1:3));
   axangSign = axangSign(axangSign ~= 0);
   if prod(axangSign == -1)
      axang(1:3) = -axang(1:3);
   end
end

rout = cell(3, 1);
[rout{:}] = quat2angle(axang2quat(axang), 'XYZ');
rout = real(rad2deg(cell2mat(rout)));
