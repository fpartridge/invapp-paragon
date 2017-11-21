function data = invappParagon(movieFile, nColumns, nRows, movementIndexThreshold, wellCircularMask)
%% Methods for analysing worm movement from movies

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


% Changelog:
% 1.000 - first public version
outputLog.invappParagonVersion      = 1.000;

outputLog.time = datestr(now);
outputLog.file = movieFile;

fprintf('Analysing %s with version %.3f of invappParagon (%s)\n', outputLog.file, outputLog.invappParagonVersion, outputLog.time);

%% DATA READING
% find out if this is a tiff
[pathstr, filename, extension] = fileparts(movieFile);

switch extension
  case '.tif'
    movieMetadata = imfinfo(movieFile);
    nFrames = numel(movieMetadata);
    % preallocate memory to array
    originalMovie = nan(movieMetadata(1).Height, movieMetadata(1).Width,nFrames);
    for i = 1:nFrames
      originalMovie(:,:,i) = imread(movieFile,i);
    end
  otherwise
    error('Unrecognised filetype %s', movieFile)
end

originalMovie = single(originalMovie); % images loaded as double but don't have enough memory

%% MEASURE MOTILITY
% keep a copy of the original movie so don't have to load it again
movementIndexImage = originalMovie;
% get variance
movementIndexImage = var(movementIndexImage,[],3);
% get the mean and standard deviation of the variance image
[varianceMean, standardDeviation] = normfit(movementIndexImage(:));
% report standard deviation as diagnostic for this movie
data.standardDeviation = standardDeviation;

%% choose pixels that are moving by choosing number of standard deviations
%% away from mean variance
%% this is determined by the movementIndexThreshold parameter
%% this is to do with the proportion of the image the moves i.e. related
%% to worm size and worm number per well
%% Suggested values:
%% Trichuris adults, C. elegans 1
%% Haemonchus L3: 3

miImage = movementIndexImage > varianceMean + movementIndexThreshold * standardDeviation;
movementIndexImage = miImage;

%% Well circular masking (optional)
%% sometimes apparent movement occurs outside the well due to
%% changes in illumination / vibration
%% therefore can optionally mask the image with an array of circles
%% corresponding to the well contents
if wellCircularMask > 0
  imageHeight = size(movementIndexImage,1);
  imageWidth = size(movementIndexImage,2);
  circleRadius = (imageWidth / nColumns) * (wellCircularMask/2);
  [W,H] = meshgrid(1:imageWidth,1:imageHeight);
  centerW = (imageWidth/nColumns) * (0.5);
  centerH = (imageHeight/nRows) * (0.5);
  mask = ((W-centerW).^2 + (H-centerH).^2) < circleRadius^2;
  for i = 1: nColumns
    for j = 1: nRows
      centerW = (imageWidth/nColumns) * (i-0.5);
      centerH = (imageHeight/nRows) * (j-0.5);
      mask = mask | ((W-centerW).^2 + (H-centerH).^2) < circleRadius^2;
    end
  end
  movementIndexImage = movementIndexImage .* mask;
end

% diagnostic image to help understand movementIndex success
data.movementIndexForeground = movementIndexImage;

% decide how to cut the image up into wells
xx = linspace(1,size(movementIndexImage,1),nRows+1);
xx = floor(xx); % choose whole numbers of pixels
yy = linspace(1,size(movementIndexImage,2),nColumns+1);
yy = floor(yy);

% count "moving" pixels in each well
movementIndex = zeros(nRows, nColumns);
for x = 1:length(xx)-1
  for y = 1:length(yy)-1
    t = movementIndexImage(xx(x):xx(x+1),yy(y):yy(y+1));
    movementIndex(x,y) = sum(t(:));
  end
end
data.movementIndex = movementIndex; %  results returned in data structure

data.outputLog   = outputLog;

end
