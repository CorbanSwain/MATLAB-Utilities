function mustBeLogicalScalar(A)
isOK = csmu.validators.logicalScalar(A);
if ~isOK
    ME = MException('csmu:validators:mustBeLogicalScalar', ...
       sprintf('Value must be a scalar logical array.'));
   throw(ME);
end
end