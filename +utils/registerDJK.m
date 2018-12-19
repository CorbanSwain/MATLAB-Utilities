function [I2Registered, tform] = registerDJK(I1, I2, varargin)

ip = inputParser;
ip.addOptional('Options', struct);
ip.StructExpand = false;
ip.parse(varargin{:});
regOptions = ip.Results.Options;

warningState = warning;
cleanup = struct;
cleanup.returnWarnState = onCleanup(@() warning(warningState));

startPath = pwd;
cleanup.returnToBasePath = onCleanup(@() cd(startPath));
extensionPath = fullfile(utils.extensionsDir, 'non_rigid_register_4d_djk_ygy');

functionFolders = {'functions', 'functions_affine', 'functions_nonrigid'};
functionFolders = utils.cellmap(@(f) fullfile(extensionPath, f), ...
   functionFolders);
cleanup.removeFromPath = onCleanup(@() rmpath(functionFolders{:}));

function val = qgf(fieldName, defaultVal)
   [val, regOptions] = utils.queryGetField(regOptions, fieldName, defaultVal);
end
qgf('Similarity', 'sd');
qgf('Registration', 'Affine');
qgf('MaxRef', 10);

warning('off');
cd(extensionPath);
addpath(functionFolders{:});

% compile_c_files;
[I2Registered, ~, ~, tform, ~, ~] = image_registration(I2 , I1, regOptions);

clear('cleanup');
end