function c = struct2argscell(S)
fields = fieldnames(S);
nFields = length(fields);
c = cell(2, nFields);
for iField = 1:nFields
   field = fields{iField};
   c(:, iField) = {field; S.(field)};
end
c = c(:)';
end