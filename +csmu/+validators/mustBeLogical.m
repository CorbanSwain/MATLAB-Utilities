function mustBeLogical(A)
isOK = islogical(A);
if ~isOK
    ME = MException('csmu:validators:mustBeLogical', ...
       sprintf('Value must be a logical array.'));
   throw(ME);
end
end