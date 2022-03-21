function mustBeLogicalScalarOrEmpty(A)
isOK = isempty(A) || csmu.validators.logicalScalar(A);
if ~isOK
    ME = MException('csmu:validators:mustBeLogicalScalar', ...
       sprintf('Value must be empty or a scalar logical array.'));
   throw(ME);
end
end