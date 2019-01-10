%cpdRegister a wrapper for the 'cpd_register' extension.
% CPD_REGISTER: Rigid, affine, non-rigid point set registration.
% The main CPD registration function that sets all the options,
% normalizes the data, runs the rigid/non-rigid registration, and returns
% the transformation parameters, registered poin-set, and the
% correspondences.
%
%   Input
%   ------------------ 
%   X, Y       real, double, full 2-D matrices of point-set locations. We want to
%              align Y onto X. [N,D]=size(X), where N number of points in X,
%              and D is the dimension of point-sets. Similarly [M,D]=size(Y). 
%   
%   opt        a structure of options with the following optional fields:
%
%       .method=['rigid','affine','nonrigid','nonrigid_lowrank'] (default
%               rigid) Registration method. Nonrigid_lowrank uses low rank
%               matrix approximation (use for the large data problems).
%       .corresp=[0 or 1] (default 0) estimate the correspondence vector at
%               the end of the registration.
%       .normalize =[0 or 1] (default 1) - normalize both point-sets to zero mean and unit
%               variance before registration, and denormalize after.
%       .max_it (default 150) Maximum number of iterations.
%       .tol (default 1e-5) Tolerance stopping criterion.
%       .viz=[0 or 1] (default 1) Visualize every every iteration.
%       .outliers=[0...1] (default 0.1) The weight of noise and outliers
%       .fgt=[0,1 or 2] Default 0 - do not use. 1 - Use a Fast Gauss transform (FGT) to speed up some matrix-vector product.
%                       2 - Use FGT and fine tune (at the end) using truncated kernel approximations.
%
%       Rigid registration options
%       .rot=[0 or 1] (default 1) 1 - estimate strictly rotation. 0 - also allow for reflections.
%       .scale=[0 or 1] (default 1) 1- estimate scaling. 0 - fixed scaling. 
%
%       Non-rigid registration options
%       .beta [>0] (default 2) Gaussian smoothing filter size. Forces rigidity.
%       .lambda [>0] (default 3) Regularization weight. 
%
%   Output
%   ------------------ 
%   Transform      structure of the estimated transformation parameters:
%
%           .Y     registered Y point-set
%           .iter  total number of iterations
%
%                  Rigid/affine cases only:     
%           .R     Rotation/affine matrix.
%           .t     Translation vector.
%           .s     Scaling constant.
%           
%                  Non-rigid cases only:
%           .W     Non-rigid coefficient
%           .beta  Gaussian width
%           .t, .s translation and scaling
%           
%    
%   C       Correspondance vector, such that Y corresponds to X(C,:)

% Copyright (C) 2008-2009 Andriy Myronenko (myron@csee.ogi.edu)
% also see http://www.bme.ogi.edu/~myron/matlab/cpd/

function [varargout] = cpdRegister(varargin)
cleanup = struct;
startPath = pwd;
cleanup.returnToBasePath = onCleanup(@() cd(startPath));
extensionPath = fullfile(csmu.extensionsDir, 'cpd_register_2', 'core');
pathsToAdd = genpath(extensionPath);
cleanup.removeFromPath = onCleanup(@() rmpath(pathsToAdd));

cd(extensionPath);
addpath(pathsToAdd);
varargout = cell(1, max(nargout, 1));
[varargout{:}] = cpd_register(varargin{:});

% explicit deletion of cleanup variable to return to the base path and
% remove extension-specific directories from the path.
clear('cleanup');
end