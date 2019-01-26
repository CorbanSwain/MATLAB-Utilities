function I = double2im(X, outputClass)
% FIXME - refactor as float2im;
I = cast(X * cast(intmax(outputClass), 'like', X), outputClass);
