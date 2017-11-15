function invappParagonTests()


resultTest = invappParagon('invappParagonTestDataset\movieA.tif',2,3,1,0);
load invappParagonTestDataset\test1ExpectedResults;

disp('Test if expected movementIndexForeground')
assert(isequal(resultTest.movementIndexForeground,resultExpected.movementIndexForeground))
disp('Test if expected movementIndex results matrix')
assert(isequal(resultTest.movementIndex, resultExpected.movementIndex))