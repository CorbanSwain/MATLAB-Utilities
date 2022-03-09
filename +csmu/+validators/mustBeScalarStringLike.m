function mustBeScalarStringLike(A)
isOK = csmu.validators.scalarStringLike(A);
if ~isOK
    ME = MException('csmu:validators:mustBeScalarStringLike', ...
       sprintf('Value must be a char vector or scalar string.'));
   throw(ME);
end
end