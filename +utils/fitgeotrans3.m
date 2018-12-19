function [tform, transformedPoints] = ...
   fitgeotrans3(movingPoints, fixedPoints, varargin)

% Parsing Inputs
tformTypes = {'rigid', 'affine'};
ip = inputParser;
ip.addOptional('TransformationType', 'affine', ...
   @(x) any(strcmpi(x, tformTypes)));
ip.parse(varargin{:});
tformType = lower(ip.Results.TransformationType);

% Checking Inputs
assert(size(movingPoints, 2) == 3);
assert(isequal(size(fixedPoints), size(movingPoints)));

nPoints = size(movingPoints, 1);
Y = reshape(fixedPoints', [], 1);

switch tformType   
   case 'affine'
      fourOnes = ones(1, 4);
      fourZeros = zeros(1, 4);
      ATemplate = [
         fourOnes,  fourZeros, fourZeros;
         fourZeros, fourOnes,  fourZeros;
         fourZeros, fourZeros, fourOnes];      
      A = cell(1, nPoints);
      for iPoint = 1:nPoints
         A{iPoint} = ATemplate .* repmat([movingPoints(iPoint, :), 1], 1, 3);
      end
      A = cat(1, A{:});      
      tform = A\Y;
      tform = reshape(tform, [], 3);
      translation = tform(4, :);
      tform = [tform(1:3, :), translation'; [0 0 0 1]]; 
      tform = utils.standard2matlabAffine(tform);
      transformedPoints = tform.transformPointsForward(movingPoints);
   case 'rigid'
      tform = [];
      
end

