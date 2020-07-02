function outputFilePaths = glob(format)
funcName = strcat('csmu.', mfilename);
L = csmu.Logger(funcName);
fileList = dir(format);
[parentDir, globFmt, globExt] = fileparts(format);
if isempty(parentDir)
   parentDir = strcat('.', filesep);
end
globFmt = strcat(globFmt, globExt);
if isempty(fileList)
   L.warn('Matched no files in\n   "%s"\n   using format "%s".',...
      strrep(parentDir, '\', '\\'), globFmt);
   outputFilePaths = {};
   return
end
nFiles = length(fileList);
L.debug('Found %d matching files in\n   "%s"\n   using format "%s".', nFiles, ...
   strrep(parentDir, '\', '\\'), globFmt);
fileNames = cell(1, nFiles);
[fileNames{:}] = fileList.name;
[fileNames, sortIdx] = sort(fileNames);

outputFilePaths = cell(nFiles, 1);
for iFile = 1:length(sortIdx)
   fileIdx = sortIdx(iFile);
   outputFilePaths{iFile} = fullfile(fileList(fileIdx).folder, ...
      fileNames{iFile});
end
end