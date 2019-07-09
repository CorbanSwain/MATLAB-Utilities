%WRITEYAML - Writes data to a file in the yaml syntax.
%
%   Recursively walks through a Matlab hierarchy and converts it to the
%   hierarchy of java.util.ArrayListS and java.util.MapS. Then calls
%   Snakeyaml to write it to a file.
%
%   Inputs:
%   -------
%      filename - path to the output file
%
%      data - data to be parsed and written
%
%      flowstyle - ???
%
%   Notes:
%   ------
%   - This function is a wrapper for the original package by Cigler et al. The 
%     package can be found online at: 
%     https://code.google.com/archive/p/yamlmatlab/

function writeYaml(varargin)
extensionPath = fullfile(csmu.extensionsDir, 'yaml_matlab_0.4.3');
cleanup = onCleanup(@() rmpath(extensionPath));
addpath(extensionPath);
WriteYaml(varargin{:});
end