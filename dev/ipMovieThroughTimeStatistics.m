function [movieVarianceImage, nPixelsInMovie, varianceMean, varianceStandardDeviation] = ipMovieThroughTimeStatistics(movie)

% get variance
movieVarianceImage = var(movie,[],3);
% get the mean and standard deviation of the variance image
[varianceMean, varianceStandardDeviation] = normfit(movieVarianceImage(:));

nPixelsInMovie = numel(movieVarianceImage);