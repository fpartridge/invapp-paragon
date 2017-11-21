[![DOI](https://zenodo.org/badge/98302026.svg)](https://zenodo.org/badge/latestdoi/98302026)

# invappParagon

A MATLAB function for analysing worm movement / growth from movies. 
The variance through time for each pixel in the plate is calculated, and the distribution of these variances examined. Pixels whose variance is greater than a threshold of the mean plus one standard deviation are determined to be “motile”.

# invappParagonBatch

Calls invappParagon for series of image files in a directory, then assembles a large table containing movement index and thrashing rate with the filename as experiment descriptor, and produces a movement image as a diagnostic.

**invappParagonBatch(folder)**

where folder is the path to a folder containing the image files

output will be written there in an analysis folder

**invappParagonBatch(folder, optionalArguments)**

where optional arguments is a cell array list of first the name of an optional argument, and then the value to use

for example: *invappParagonBatch(folder,{'plateRows',4})*

Arguments:

'plateColumns'            Default: 12

'plateRows'               Default: 8

'movementIndexThreshold'  Default: 1    Threshold for movement index moving/not moving pixels.

'wellCircularMark'        Default: 0
       
An array of circular masks can be applied to the movie to ignore apparent movement outside circular wells (typically due to changes in illumination or vibration during movie capture). If 0 there is no masking of areas of a plate outside the well. Otherwise values from 0-1 = circular mask radius as a proportion of the width/height of the rectangle containing the well
