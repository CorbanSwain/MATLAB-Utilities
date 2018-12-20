function mustBeValidRotationUnit(val)
isOK = any(strcmpi(val, {'rad', 'deg'}));
if ~isOK
    ME = MException('utils:validators:mustBeRotationUnit', ...
       'Value mist be a valid rotation unit, either ''rad'', or ''deg''');
   throw(ME);
end
end