function [val, S] = queryGetField(S, fieldName, default)
% queryGetField Gets the field or a default value from a struct.
%
% S: the struct to get the value from
% fieldName: the name of the field
% default: the value to be returned if the field does not exist
%
% This function is most useful if it is locally redefiend to automatically
% update a local struct. For example:
% function val = qgf(fieldName, default);
%     [val, localStruct] = queryGetField(localStruct, fieldName, default);
% end

if ~isfield(S, fieldName)
    S.(fieldName) = default;
end
val = S.(fieldName);
end