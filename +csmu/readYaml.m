%READYAML - Actually reads YAML file and transforms it using several mechanisms
%
%   - Transforms mappings and lists into Matlab structs and cell arrays,
%     for timestamps uses DateTime class, performs all imports (when it
%     finds a struct field named 'import' it opens file(s) named in the
%     field content and substitutes the filename by their content.
%   - Deflates outer imports into inner imports - see deflateimports(...)
%     for details.
%   - Merges imported structures with the structure from where the import
%     was performed. This is actually the same process as inheritance with
%     the difference that parent is located in a different file.
%   - Does inheritance - see doinheritance(...) for details.
%   - Makes matrices from cell vectors - see makematrices(...) for details.
%
%   Inputs:
%   -------
%      filename - name of an input yaml file
%
%      nosuchfileaction - Determines what to do if a file to read is
%                         missing:
%                            * 0 or not present - missing file will only throw
%                                                 a warning
%                            * 1 - missing file throws an exception and halts 
%                                  the process
%
%      makeords - Determines whether to convert cell array to
%                 ordinary matrix whenever possible (1).
%                    * type: logical scalar
%
%      treatasdata - If this flag is set to true (1), the char array of a yaml
%                    file should be passed instead of a filepath for the
%                    `filename` parameter.
%                       * type: logical scalar
%
%      dictionary - Dictionary of of labels that will be replaced,
%                   struct is expected
%
%   Notes:
%   ------
%   - This function is a wrapper for the original package by Cigler et al. The 
%     package can be found online at: 
%     https://code.google.com/archive/p/yamlmatlab/

% Corban Swain, 2019

function result = readYaml(varargin)
extensionPath = fullfile(csmu.extensionsDir, 'yaml_matlab_0.4.3');
cleanup = onCleanup(@() rmpath(extensionPath));
addpath(extensionPath);
result = ReadYaml(varargin{:});
end