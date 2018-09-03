function loadOneFileCalcThreshold(movieFile)

%% Copyright 2018 Steven Buckingham and Freddie Partridge

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


%% DATA READING
% find out if this is a tiff
[pathstr, filename, extension] = fileparts(movieFile);

switch extension
  case '.tif'
    movieMetadata = imfinfo(movieFile);
    nFrames = numel(movieMetadata);
    % preallocate memory to array
    originalMovie = nan(movieMetadata(1).Height, movieMetadata(1).Width,nFrames);
    % is it a greyscale or colour movie. If colour convert to grey
    switch movieMetadata(1).ColorType
      case 'grayscale'
        for i = 1:nFrames
          originalMovie(:,:,i) = imread(movieFile,i);
        end    
      case 'truecolor' 
        for i = 1:nFrames
          originalMovie(:,:,i) = rgb2gray(imread(movieFile,i));
        end   
      otherwise
        error('Problem understanding colour type of %s', movieFile)
    end
  otherwise
    error('Unrecognised filetype %s', movieFile)
end

originalMovie = single(originalMovie); % images loaded as double but don't have enough memory

%% MEASURE MOTILITY
% get variance
movementIndexImage = var(originalMovie,[],3);
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
movementIndexThreshold = 1;

absoluteThreshold = varianceMean + movementIndexThreshold * standardDeviation
