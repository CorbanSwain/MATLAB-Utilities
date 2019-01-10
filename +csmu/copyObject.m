function outObj = copyObject(inObj, outObj)
mc = metaclass(inObj);
props = mc.Properties;
for iProp = 1:length(props)
   if ~props{iProp}.Dependent
      outObj.(props{iProp}.Name) = inObj.(props{iProp}.Name);
   end
end
end