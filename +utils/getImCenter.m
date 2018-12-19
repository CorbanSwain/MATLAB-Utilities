function center = getImCenter(sz)
if ~isa(sz, 'imref3d')
   ref = imref3d(sz);
else
   ref = sz;
end

center = [ ...
   mean(ref.XWorldLimits), ...
   mean(ref.YWorldLimits), ...
   mean(ref.ZWorldLimits)];
end