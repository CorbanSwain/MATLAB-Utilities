% wrapper for builtin `imwarp` function.

function [varargout] = imwarp(A, RA, transform, nvInputs)
arguments
   A {mustBeNumeric}
   RA (1, 1) csmu.ImageRef
   transform
   nvInputs.DoInverse {csmu.validators.mustBeLogicalScalar}
   nvInputs.OutputView (1, 1) csmu.ImageRef = []
   nvInputs.FillValues {mustBeNumeric} = []
   nvInputs.SmoothEdges (1, 1) logical = true   
end

funcName = strcat('csmu.', mfilename());
L = csmu.Logger(funcName);


%% Input Handling
L.assert(any(strcmpi(class(transform), {'csmu.Transform', 'affine3d'})), ...
   '`csmu.Transform` or `affine3d` object must be supplied for transform.');

RA_builtin = RA.Ref;

if ~isempty(nvInputs.OutputVies)
   doUseOutputView = true;
   RB = nvInputs.OutputView;
   RB_builtin = RB.Ref;
else
   doUseOutputView = false;
end


%% Setup
L.debug('Preparing to perform image warp.');
if isa(transform, 'csmu.Transform')
   affineTransform = transform.computeAffineObject(...
      'DoInverse', nvInputs.DoInverse);
else
   affineTransform = transform;
end   

warpArgs = {A, RA_builtin, affineTransform};

if doUseOutputView
   warpArgs = [warpArgs, {'OutputView', RB_builtin}];
end

if ~isempty(nvInputs.FillValues)
   warpArgs = [warpArgs, {'FillValues', nvInputs.FillValues}];
end 

warpArgs = [warpArgs, {'SmoothEdges', nvInputs.SmoothEdges}];

switch nargout
   case 2
      varargout = cell(1, 2);
   otherwise
      varargout = cell(1, 1);
end


%% Function Call
t1 = tic();
[varargout{:}] = builtin('imwarp', warpArgs{:});
L.debug('...imwarp took %s', csmu.durationString(toc(t1)));
end