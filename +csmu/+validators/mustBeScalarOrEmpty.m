function mustBeScalarOrEmpty(A)
isOK = isscalar(A) || isempty(A);
if ~isOK
    ME = MException('csmu:validators:mustBeScalorOrEmpty', ...
       sprintf('Value must be a scalar or an empty array.'));
   throw(ME);
end
end