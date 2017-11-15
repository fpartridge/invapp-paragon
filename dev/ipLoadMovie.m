function movie = ipLoadMovie(movieFile)

%% DATA READING
% find out if this is a tiff
[pathstr, filename, extension] = fileparts(movieFile);

switch extension
  case '.tif'
    movieMetadata = imfinfo(movieFile);
    nFrames = numel(movieMetadata);
    % preallocate memory to array
    movie = nan(movieMetadata(1).Height, movieMetadata(1).Width,nFrames);
    for i = 1:nFrames
      movie(:,:,i) = imread(movieFile,i);
    end
  otherwise
    error('Unrecognised filetype %s', movieFile)
end

movie = single(movie); % images loaded as double but don't have enough memory