function fileList = ipMakeListOfFilesToAnalyse(folder)

%% look for .tif files in subfolders
fileList = dirrec(folder, '.tif');
fileList = cellstr(fileList);

