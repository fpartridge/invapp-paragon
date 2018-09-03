function invappParagonBatch(folder, optionalArguments)
%% Automated experiment processing in INVAPP Paragon
%%
%% Copyright 2017 Steven Buckingham and Freddie Partridge

% MIT License:
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

%% Calls invappParagon for series of image files in a directory,
%% then assembles large table containing movement index and thrashing rate
%% with the filename as experiment descriptor
%%
%% Usage: invappParagonBatch(folder)
%% where folder is the path to a folder containing the image files
%% output will be written there in an analysis folder
%%
%% Usage: invappParagonBatch(folder, optionalArguments)
%% where optional arguments is a cell array list of first the name of an optional argument, and then
%% the value to use
%% for example: invappParagonBatch(folder,{'plateRows',4})
%%
% Arguments:
% 'plateColumns'            Default: 12
% 'plateRows'               Default: 8
% 'movementIndexThreshold'  Default: 1
%       Threshold for movement index moving/not moving pixels.
% 'wellCircularMask'        Default: 0
%       An array of circular masks can be applied to the movie to ignore
%       apparent movement outside circular wells (typically due to changes
%       in illumination or vibration during movie capture).
%       If 0 there is no masking of areas of a plate outside the well
%       Otherwise values from 0-1 = circular mask radius as a proportion
%       of the width/height of the rectangle containing the well
% 'specifyAbsoluteThreshold' Default : 0
%       In some situations might want to specify a certain threshold for
%       motile pixel variance instead of calculating from each movie
%%
%% Changelog


log.invappParagonBatchVersion  = 1.003;
log.folder          = folder;
log.time            = datestr(now,'yyyymmdd-HHMM');

outputFolder = strcat(folder,filesep,'Analysis_',log.time);

if ~exist(outputFolder)
    mkdir(folder,strcat('Analysis_',log.time));
end

if nargin > 2
    error('Too many arguments for invappParagonBatch');
end
if nargin < 1
    error('invappParagonBatch needs at least one argument');
end

% logging
[outputLog, message] = fopen([outputFolder,filesep,'invappParagonBatchLog.txt'],'wt');
if outputLog < 0
    disp(message);
end

% log the command typed
historypath = com.mathworks.mlservices.MLCommandHistoryServices.getSessionHistory;
lastexpression = historypath(end).toCharArray()';
fprintf(outputLog,'Executing command: %s\n\n',lastexpression);


fprintf(outputLog,'Running invappParagonBatch version %.3f, on folder %s (%s)\n', log.invappParagonBatchVersion, log.folder, log.time);
if ~exist([outputFolder, filesep,'invappParagonDiagnostics'])
    mkdir(outputFolder,'invappParagonDiagnostics');
end

%% dealing with optional parameters

% default options
frameRange.start = 0;
frameRange.end = 0;
options = struct(   'plateColumns',12,'plateRows',8,...
                    'movementIndexThreshold',1,'wellCircularMask',0,...
                    'specifyAbsoluteThreshold',0);
% if passed optional arguments then overwrite the defaults
if nargin == 2
    optionNames = fieldnames(options);
    % check have been passed pairs of optional arguments
    nArgs = length(optionalArguments);
    if round(nArgs/2) ~= nArgs/2
        error ('Optional arguments must be paired');
    end
    for pair = reshape(optionalArguments,2,[])
        inpName = pair{1}; % case insensitive
        if any(strmatch(inpName, optionNames))
            % overwrite default options
            options.(inpName) = pair{2};
        else
           error('%s is not a recognized parameter',inpName);
        end
    end
end
nColumns = getfield(options,'plateColumns');
nRows    = getfield(options,'plateRows');
nWells   = nColumns * nRows;
fprintf(outputLog,'%dx%d wells per image\n\n', nColumns, nRows);
movementIndexThreshold = getfield(options,'movementIndexThreshold');
wellCircularMask = getfield(options,'wellCircularMask');
specifyAbsoluteThreshold = getfield(options,'specifyAbsoluteThreshold');



%% look for .tif files in subfolders
imageFileList = dirrec(folder, '.tif');
imageFileList = cellstr(imageFileList);


%% write table headings into csv file
resultsFilename = [outputFolder,filesep,'invappParagonBatchResults',log.time,'.csv'];
headings={'filename','well','row','column','movementScore'};
writeCellArrayToCSV(resultsFilename,headings,0);

%% Run initial analysis
for filenameIndex = 1:numel(imageFileList)
    filename = imageFileList(filenameIndex);

    % build tables for experiment
    experiment = repmat(filename,nWells,1);

    %run INVAPP Paragon
    filename = filename{:};
    data = invappParagon(filename,nColumns,nRows,movementIndexThreshold,wellCircularMask,specifyAbsoluteThreshold);

    ipMovements = reshape(data.movementIndex,nWells,1);
    ipMovements = cellstr(num2str(ipMovements(:))); % cast to cell
    experiment  = cellstr(experiment);

    % well coordinate labels
    wellCoordinates = cell(1,nWells);
    wellRow = cell(1,nWells);
    wellColumn = cell(1,nWells);
    count=0;
    rowlabels='ABCDEFGHIJKLMNOPQRSTUV';
    for x=1:nColumns
        for y=1:nRows
            count = count + 1;
            wellCoordinates{count}=[rowlabels(y),num2str(x,'%02d')];
            wellRow{count} = rowlabels(y);
            wellColumn{count} = [num2str(x)];
        end
    end
    wellCoordinates = wellCoordinates';
    wellCoordinates = cellstr(wellCoordinates);
    wellRow = wellRow';
    wellRow = cellstr(wellRow);
    wellColumn = wellColumn';
    wellColumn = cellstr(wellColumn);

    results=[experiment,wellCoordinates,wellRow,wellColumn,ipMovements];

    % analysis of each movie file written sequentially in the csv output
    fileRow=nWells*(filenameIndex-1)+2;
    startCell=strcat('A',num2str(fileRow));
    writeCellArrayToCSV(resultsFilename,results,1);

    fprintf(outputLog,'  Ran invappParagon version %.3f, on file %s (%s)\n', data.outputLog.invappParagonVersion, data.outputLog.file, data.outputLog.time);

    % diagnostics for movement index
    % check foreground v background separation correct

    % because micromanager writes ome-tiff in subfolders for some reason
    [pathstr, filename, ext] = fileparts(filename);

    if ~exist([outputFolder, filesep,'invappParagonDiagnostics', filesep, 'Movement index foreground'])
        mkdir([outputFolder,filesep,'invappParagonDiagnostics'],'Movement index foreground');
    end
    f=figure('Name', ['Movement index for file ',filename],'Visible','off');
    imagesc(data.movementIndexForeground);
    axis equal;
    axis off;
    print(f, '-r300', '-dpng', [outputFolder, filesep,'invappParagonDiagnostics',filesep,'Movement index foreground',filesep,filename,num2str(filenameIndex),'.png']);

clear data;
end

fclose(outputLog);

end

function writeCellArrayToCSV(filename,data,append)
% csvwrite has a completely ludicrous inability to export cell arrays with
% mixed alphabetic and numeric data see:
% http://www.mathworks.co.uk/help/techdoc/ref/csvwrite.html and
% http://www.mathworks.co.uk/help/techdoc/import_export/f5-15544.html#br2ypq2-1
% (at least in version R2012a)

if (append)
    fileHandle = fopen(filename,'a');
else
    fileHandle = fopen(filename,'w');
end


if (fileHandle < 0)
    error(['Cannot open file ', filename, ' - check that it is not open in another program']);
end

[nrows,ncols]= size(data);
for i=1:nrows
    fprintf(fileHandle,'%s,',data{i,1:end-1});
    fprintf(fileHandle,'%s\n',data{i,end});
end

fclose(fileHandle);
end
