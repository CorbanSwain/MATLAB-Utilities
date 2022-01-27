function bool = doFieldsMatch(s1, s2)

arguments
   s1 {mustBeStruct}
   s2 {mustBeStruct}
end

f1 = fieldnames(s1);
f2 = fieldnames(s2);
bool = all(contains(f1, f2)) && all(contains(f2, f1));
end

function mustBeStruct(x)
assert(isstruct(x), 'Value must be of type struct.');
end