function f = calcZFactor(PSF)
L = csmu.Logger('csmu.calcZFactor');
f = PSF.zspacing / diff(PSF.x1objspace(1:2));
if ~csmu.isint(f)
   L.warn('Expected zFactor to be an integer.');
end
f = round(f);
