//
//  Detector.m
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 28/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#include <opencv2/core/core.hpp>
#include <opencv2/ml/ml.hpp>
#include <stdlib.h>

#import "Detector.h"
#import "UIImage+HOG.h"
#import "UIImage+Resize.h"
#import "ConvolutionHelper.h"
#import "BoundingBox.h"

using namespace cv;

#define MAX_QUOTA 100 //max negative examples (bb) per iteration
#define MAX_NUMBER_EXAMPLES (MAX_QUOTA + 200)*20 //max number of examples in buffer, (500neg + 200pos)*20images
#define STOP_CRITERIA 0.05 
#define MAX_IMAGE_SIZE 300.0
#define SCALES_PER_OCTAVE 10
#define MAX_TRAINING_ITERATIONS 10

//training results
#define SUCCESS 1
#define INTERRUPTED 2 //and not trained
#define FAIL 0

@interface Detector ()
{
    int *_sizesP; //Array with the dimensions of the features: hog_width x hog_height x features_per_hog_bin
    double *_weightsP; //Array with the weights obtained in each dimension
    
    int _numOfFeatures;
    int _numSupportVectors;
    float _diff;
    int _levelsPyramid[10]; //how many bb of each level do we obtain
    
    BOOL _isLearning;
    
    //pyramid limits for detection in execution
    int _iniPyramid;
    int _finPyramid;
    
    //detector buffer (when training)
    NSMutableArray *_receivedImageIndex;
    NSMutableArray *_imagesHogPyramid;
    
    BOOL _isTrainCancelled;
    
    float *_trainingImageLabels; //Array containg the labels for the training set
    float *_trainingImageFeatures; //Matrix containing the features for each image of the training set
    int _numberOfTrainingExamples; //Counter of the total number of training images
}


// Show just the histogram features for debugging purposes
- (void) showOrientationHistogram;

// Make the convolution of the detector with the image and return de detected bounding boxes
- (NSArray *) getBoundingBoxesIn:(HogFeature *)imageHog forPyramid:(int)pyramidLevel forIndex:(int)imageHogIndex;

// Add a selected bounding box (its correspondent hog features) to the training buffer
- (void) addExample:(BoundingBox *)p to:(TrainingSet *)trainingSet;

// Calculate difference of weight wihtin an iteration to find that difference
- (double) computeDifferenceWithLastWeights:(double *) weightsPLast;

// Print unoriented hog features for debugging purposes
- (void) printListHogFeatures:(float *) listOfHogFeaturesFloat;

@end


@implementation Detector


#pragma mark -
#pragma mark Initialization & Encoding

- (id) init
{
    if (self = [super init]) {
        //dummy initialization to be replaced during the training
        _sizesP = (int *) malloc(3*sizeof(int)); _sizesP[0] = 1; _sizesP[1] = 1; _sizesP[2] = 1;
        _weightsP = (double *) malloc(sizeof(double)); _weightsP[0] = 0;
    }
    
    return self;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.weights = [aDecoder decodeObjectForKey:@"weights"];
        self.sizes = [aDecoder decodeObjectForKey:@"sizes"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.detectorID = [aDecoder decodeObjectForKey:@"detectorID"];
        self.targetClasses = [aDecoder decodeObjectForKey:@"targetClasses"];
        self.numberSV = [aDecoder decodeObjectForKey:@"numberSV"];
        self.numberOfPositives = [aDecoder decodeObjectForKey:@"numberOfPositives"];
        self.precisionRecall = [aDecoder decodeObjectForKey:@"precisionRecall"];
        self.timeLearning = [aDecoder decodeObjectForKey:@"timeLearning"];
        self.imagesUsedTraining = [aDecoder decodeObjectForKey:@"imagesUsedTraining"];
        self.averageImagePath = [aDecoder decodeObjectForKey:@"averageImagePath"];
        self.averageImageThumbPath = [aDecoder decodeObjectForKey:@"averageImageThumbPath"];
        self.updateDate = [aDecoder decodeObjectForKey:@"updateDate"];
        self.scaleFactor = [aDecoder decodeObjectForKey:@"scaleFactor"];
        self.detectionThreshold = [aDecoder decodeObjectForKey:@"detectionThreshold"];
        
        free(_sizesP);
        _sizesP = (int *) malloc(3*sizeof(int));
        _sizesP[0] = [(NSNumber *) [self.sizes objectAtIndex:0] intValue];
        _sizesP[1] = [(NSNumber *) [self.sizes objectAtIndex:1] intValue];
        _sizesP[2] = [(NSNumber *) [self.sizes objectAtIndex:2] intValue];
        
        int numberOfWeights = _sizesP[0]*_sizesP[1]*_sizesP[2] + 1; //+1 for the bias
        
        free(_weightsP);
        _weightsP = (double *) malloc(numberOfWeights*sizeof(double));
        for(int i=0; i<numberOfWeights; i++)
            _weightsP[i] = [(NSNumber *) [self.weights objectAtIndex:i] doubleValue];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    self.sizes = [[NSArray alloc] initWithObjects:
                  [NSNumber numberWithInt:_sizesP[0]],
                  [NSNumber numberWithInt:_sizesP[1]],
                  [NSNumber numberWithInt:_sizesP[2]], nil];
    
    int numberOfSvmWeights = _sizesP[0]*_sizesP[1]*_sizesP[2] + 1; //+1 for the bias
    
    self.weights = [[NSMutableArray alloc] initWithCapacity:numberOfSvmWeights];
    for(int i=0; i<numberOfSvmWeights; i++)
        [self.weights addObject:[NSNumber numberWithDouble:_weightsP[i]]];
    
    
    [aCoder encodeObject:self.weights forKey:@"weights"];
    [aCoder encodeObject:self.sizes forKey:@"sizes"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.detectorID forKey:@"detectorID"];
    [aCoder encodeObject:self.targetClasses forKey:@"targetClasses"];
    [aCoder encodeObject:self.numberSV forKey:@"numberSV"];
    [aCoder encodeObject:self.numberOfPositives forKey:@"numberOfPositives"];
    [aCoder encodeObject:self.precisionRecall forKey:@"precisionRecall"];
    [aCoder encodeObject:self.timeLearning forKey:@"timeLearning"];
    [aCoder encodeObject:self.imagesUsedTraining forKey:@"imagesUsedTraining"];
    [aCoder encodeObject:self.averageImagePath forKey:@"averageImagePath"];
    [aCoder encodeObject:self.averageImageThumbPath forKey:@"averageImageThumbPath"];
    [aCoder encodeObject:self.updateDate forKey:@"updateDate"];
    [aCoder encodeObject:self.scaleFactor forKey:@"scaleFactor"];
    [aCoder encodeObject:self.detectionThreshold forKey:@"detectionThreshold"];
    
}

- (void) dealloc
{
    free(_sizesP);
    free(_weightsP);
}


#pragma mark -
#pragma mark Getters and Setters

- (NSNumber *) detectionThreshold
{
    if(!_detectionThreshold) _detectionThreshold = [NSNumber numberWithFloat:0.5];
    return _detectionThreshold;
}


#pragma mark -
#pragma mark Public Methods

- (int) trainOnSet:(TrainingSet *)trainingSet forMaxHOG:(int)maxHog;
{
    NSDate *start = [NSDate date]; //to compute the training time.

    _isLearning = YES;
    
    //array initialization
    _imagesHogPyramid = [[NSMutableArray alloc] init];
    for (int i = 0; i < trainingSet.images.count*10; ++i)
        [_imagesHogPyramid addObject:[NSNull null]];
    _receivedImageIndex = [[NSMutableArray alloc] init];
    
    //set hog dimension according to the max Hog set in user preferences
    float ratio;
    if(trainingSet.templateSize.height > trainingSet.templateSize.width){
        ratio = trainingSet.templateSize.width/trainingSet.templateSize.height;
        _sizesP[0] = maxHog; //set in user preferences
        _sizesP[1] = round(_sizesP[0]*ratio);

    }else{
        ratio = trainingSet.templateSize.height/trainingSet.templateSize.width;
        _sizesP[1] = maxHog;
        _sizesP[0] = round(_sizesP[1]*ratio);
    }
    _sizesP[2] = 31;
    
    //scalefactor for detection. Used to ajust hog size with images resolution
    self.scaleFactor = [NSNumber numberWithDouble:maxHog*pixelsPerHogCell*sqrt(ratio/trainingSet.areaRatio)];
    _numOfFeatures = _sizesP[0]*_sizesP[1]*_sizesP[2];
    
    [self.delegate sendMessage:[NSString stringWithFormat:@"Hog features: %d %d %d for ratio:%f", _sizesP[0],_sizesP[1],_sizesP[2], ratio]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"area ratio: %f", trainingSet.areaRatio]];
    
    //define buffer sizes
    //TODO: max size for the buffers
    _trainingImageFeatures = (float *) malloc(MAX_NUMBER_EXAMPLES*_numOfFeatures*sizeof(float));
    _trainingImageLabels = (float *) malloc(MAX_NUMBER_EXAMPLES*sizeof(float));
    
    //convergence loop
    free(_weightsP);
    _weightsP = (double *) calloc((_numOfFeatures + 1),sizeof(double));
    for(int i=0; i<_numOfFeatures+1; i++) _weightsP[i] = 1;
    double *weightsPLast = (double *) calloc((_numOfFeatures + 1),sizeof(double));
    _diff = 1;
    int iter = 0;
    _numSupportVectors=0;
    BOOL firstTimeError = YES;
    
    while(_diff > STOP_CRITERIA && iter<MAX_TRAINING_ITERATIONS && !_isTrainCancelled){

        [self.delegate sendMessage:[NSString stringWithFormat:@"\n******* Iteration %d *******", iter]];
        
        //Get Bounding Boxes from detection
        [self getBoundingBoxesForTrainingSet:trainingSet];
        
        //The first time that not enough positive or negative bb have been generated (due to bb with different geometries), try to unify all the sizes of the bounding boxes. This solve the problem in most of the cases at the cost of losing accuracy. However if still not solved, give an error saying not possible training done due to the ground truth bouning boxes shape.
        if(self.numberOfPositives.intValue < 2 || self.numberOfPositives.intValue == _numberOfTrainingExamples){
            if(firstTimeError){
                [trainingSet unifyGroundTruthBoundingBoxes];
                firstTimeError = NO;
                continue;
            }else{
                free(weightsPLast);
                free(_trainingImageFeatures);
                free(_trainingImageLabels);
                return FAIL;
            }
        }
        
        //Train the SVM, update weights and store support vectors and labels
        [self trainSVMAndGetWeights];
        
        _diff = [self computeDifferenceWithLastWeights:weightsPLast];
        iter++;
        if(iter!=1) [self.delegate updateProgress:STOP_CRITERIA/_diff];
    }
    
    if(_isTrainCancelled){
        [self.delegate sendMessage:@"\n TRAINING INTERRUPTED \n"];
        free(weightsPLast);
        free(_trainingImageFeatures);
        free(_trainingImageLabels);
        return INTERRUPTED;
    }

    //update information about the detector
    self.numberSV = [NSNumber numberWithInt:_numSupportVectors];
    self.timeLearning = [NSNumber numberWithDouble:-[start timeIntervalSinceNow]];
    
    //See the results on training set
    [self.delegate updateProgress:1];
    _isLearning = NO;
    _imagesHogPyramid = nil;
    _receivedImageIndex = nil;
    free(weightsPLast);
    free(_trainingImageFeatures);
    free(_trainingImageLabels);
    
    return SUCCESS; 
}


- (NSArray *) detect:(UIImage *)image
    minimumThreshold:(double) detectionThreshold
            pyramids:(int)numberPyramids
            usingNms:(BOOL)useNms
   deviceOrientation:(int)orientation
  learningImageIndex:(int) imageIndex

{
    NSMutableArray *candidateBoundingBoxes = [[NSMutableArray alloc] init];

    //scaling factor for the image
    float ratio = image.size.width*1.0 / image.size.height;
    double initialScale = self.scaleFactor.doubleValue/sqrt(image.size.width*image.size.width);
    if(ratio>1) initialScale = initialScale * 1.3; 
    double scale = pow(2, 1.0/SCALES_PER_OCTAVE);

    //Pyramid limits
    if(_finPyramid == 0) _finPyramid = numberPyramids;
    
    //locate pyramids already calculated in the buffer
    BOOL found=NO;
    if(_isLearning){
        
        //pyramid limits
        _iniPyramid = 0; _finPyramid = numberPyramids;
        
        //Locate pyramids in buffer
        found = YES;
        if([_receivedImageIndex indexOfObject:[NSNumber numberWithInt:imageIndex]] == NSNotFound || _receivedImageIndex.count == 0){
            [_receivedImageIndex addObject:[NSNumber numberWithInt:imageIndex]];
            found = NO;
        }
    }
    
    dispatch_queue_t pyramidQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    UIImage *im = [image scaleImageTo:initialScale/pow(scale,_iniPyramid)];
    dispatch_apply(_finPyramid - _iniPyramid, pyramidQueue, ^(size_t i) {
        HogFeature *imageHog;
        int imageHogIndex = 0;
        float scaleLevel = pow(1.0/scale, i);
        if(!found){
            imageHog = [[im scaleImageTo:scaleLevel] obtainHogFeatures];
//            NSLog(@"Pyramid %zd, numblocs x:%d, numblocks y:%d", i, imageHog.numBlocksX, imageHog.numBlocksY);
            
            if(_isLearning){
                imageHogIndex = imageIndex*numberPyramids + i + _iniPyramid;
                [_imagesHogPyramid replaceObjectAtIndex:imageHogIndex withObject:imageHog];
            }
        }else{
            imageHogIndex = (imageIndex*numberPyramids + i + _iniPyramid);
            imageHog = (HogFeature *)[_imagesHogPyramid objectAtIndex:imageHogIndex];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [candidateBoundingBoxes addObjectsFromArray:[self getBoundingBoxesIn:imageHog forPyramid:i + _iniPyramid forIndex:imageHogIndex]];
        });
    });
    dispatch_release(pyramidQueue);
    
    
    //sort array of bounding boxes by score
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *candidateBoundingBoxesSorted = [candidateBoundingBoxes sortedArrayUsingDescriptors:sortDescriptors];
    
    NSArray *nmsArray = candidateBoundingBoxesSorted;
    if(useNms) nmsArray = [ConvolutionHelper nms:candidateBoundingBoxesSorted maxOverlapArea:0.25 minScoreThreshold:detectionThreshold]; 

    if(!_isLearning && nmsArray.count > 0){
        //get the level of the maximum score bb
        int level = [(BoundingBox*)[nmsArray objectAtIndex:0] pyramidLevel];
        _iniPyramid = level-1 > -1 ? level - 1 : 0;
        _finPyramid = level+2 < numberPyramids ? level+2 : numberPyramids;
    }else{
        _iniPyramid = 0;
        _finPyramid = numberPyramids;
    }
    
    // Change the resulting orientation of the bounding boxes if the phone orientation requires it
    if(!_isLearning && UIInterfaceOrientationIsLandscape(orientation)){
        for(int i=0; i<nmsArray.count; i++){
            BoundingBox *boundingBox = [nmsArray objectAtIndex:i];
            double auxXmin, auxXmax;
            auxXmin = boundingBox.xmin;
            auxXmax = boundingBox.xmax;
            boundingBox.xmin = (1 - boundingBox.ymin);
            boundingBox.xmax = (1 - boundingBox.ymax);
            boundingBox.ymin = auxXmin;
            boundingBox.ymax = auxXmax;
        }
    }
    return nmsArray;
}



- (NSArray *) detect:(Pyramid *) pyramid
    minimumThreshold:(double) detectionThreshold
            usingNms:(BOOL)useNms
         orientation:(int)orientation
{
    //get detections for each pyramid level (parallel processing)
    NSMutableArray *candidateBoundingBoxes = [[NSMutableArray alloc] init];    
    __block NSArray *candidatesForLevel;
    dispatch_queue_t pyramidQueue = dispatch_queue_create("pyramidQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(_finPyramid - _iniPyramid, pyramidQueue, ^(size_t i) {
        if([[pyramid.hogFeatures objectAtIndex:i + _iniPyramid] isKindOfClass:[HogFeature class]]){
            __block HogFeature *imageHog;
            dispatch_sync(dispatch_get_main_queue(), ^{
                imageHog = [pyramid.hogFeatures objectAtIndex:i + _iniPyramid];
            });
            candidatesForLevel = [self getBoundingBoxesIn:imageHog forPyramid:i+_iniPyramid forIndex:0];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [candidateBoundingBoxes addObjectsFromArray:candidatesForLevel];
        });
    });
    dispatch_release(pyramidQueue);
    
//    int i=0;
//    for(HogFeature* imageHog in pyramid.hogFeatures){
//        [candidateBoundingBoxes addObjectsFromArray:[self getBoundingBoxesIn:imageHog forPyramid:i+self.iniPyramid forIndex:0]];
//        i++;
//    }
    
    
    //sort array of bounding boxes by score
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *candidateBoundingBoxesSorted = [candidateBoundingBoxes sortedArrayUsingDescriptors:sortDescriptors];
    
    //non maximum supression
    NSArray *nmsArray = candidateBoundingBoxesSorted;
    if(useNms) nmsArray = [ConvolutionHelper nms:candidateBoundingBoxesSorted maxOverlapArea:0.25 minScoreThreshold:detectionThreshold];
    
    //update the pyramid object with the desired pyramids for the next time
    if(nmsArray.count > 0){
        //get the level of the maximum score bb
        int level = [(BoundingBox*)[nmsArray objectAtIndex:0] pyramidLevel];
        _iniPyramid = level-1 > -1 ? level - 1 : 0;
        _finPyramid = level+2 < pyramid.numPyramids ? level+2 : pyramid.numPyramids;
    }else{
        _iniPyramid = 0;
        _finPyramid = pyramid.numPyramids;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        for(int i=_iniPyramid;i<_finPyramid;i++)
            [pyramid.levelsToCalculate addObject:[NSNumber numberWithInt:i]];
    });

    
    // Change the resulting orientation of the bounding boxes if the phone orientation requires it
    if(!_isLearning && UIInterfaceOrientationIsLandscape(orientation)){
        for(int i=0; i<nmsArray.count; i++){
            BoundingBox *boundingBox = [nmsArray objectAtIndex:i];
            double auxXmin, auxXmax;
            auxXmin = boundingBox.xmin;
            auxXmax = boundingBox.xmax;
            boundingBox.xmin = (1 - boundingBox.ymin);
            boundingBox.xmax = (1 - boundingBox.ymax);
            boundingBox.ymin = auxXmin;
            boundingBox.ymax = auxXmax;
        }
    }
    
    return nmsArray;
}


- (void) testOnSet:(TrainingSet *)testSet atThresHold:(float)detectionThreshold
{
    
    _isLearning = YES;
    //TODO: not multiimage
    int tp=0, fp=0, fn=0;// tn=0;
    for(BoundingBox *groundTruthBoundingBox in testSet.groundTruthBoundingBoxes){
        bool found = NO;
        UIImage *selectedImage = [testSet.images objectAtIndex:groundTruthBoundingBox.imageIndex];
        NSArray *detectedBoundingBoxes = [self detect:selectedImage minimumThreshold:detectionThreshold pyramids:10 usingNms:YES deviceOrientation:UIImageOrientationUp learningImageIndex:groundTruthBoundingBox.imageIndex];
        for(BoundingBox *detectedBoundingBox in detectedBoundingBoxes)
            if ([detectedBoundingBox fractionOfAreaOverlappingWith:groundTruthBoundingBox]>0.5){
                tp++;
                found = YES;
            }else fp++;
        
        if(!found) fn++;
        //NSLog(@"tp at image %d: %d", groundTruthBoundingBox.imageIndex, tp);
        //NSLog(@"fp at image %d: %d", groundTruthBoundingBox.imageIndex, fp);
        //NSLog(@"fn at image %d: %d", groundTruthBoundingBox.imageIndex, fn);
    }

    [self.delegate sendMessage:[NSString stringWithFormat:@"PRECISION: %f", tp*1.0/(tp+fp)]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"RECALL: %f", tp*1.0/(tp+fn)]];
    self.precisionRecall = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:tp*1.0/(tp+fp)],[NSNumber numberWithDouble:tp*1.0/(tp+fn)] ,nil];
    
    _isLearning = NO;
}


-(void) cancelTraining
{
    _isTrainCancelled = YES;
}


- (UIImage *) getHogImageOfTheWeights
{
    return [UIImage hogImageFromFeatures:_weightsP withSize:_sizesP];
}

#pragma mark -
#pragma mark Private methods

- (void) showOrientationHistogram
{
    double *histogram = (double *) calloc(18,sizeof(double));
    for(int x = 0; x<_sizesP[1]; x++)
        for(int y=0; y<_sizesP[0]; y++)
            for(int f=18; f<27; f++)
                histogram[f-18] += _weightsP[y + x*_sizesP[0] + f*_sizesP[0]*_sizesP[1]];
    
    printf("Orientation Histogram\n");
    for(int i=0; i<9; i++)
        printf("%f ", histogram[i]);
    printf("\n");
    
    free(histogram);
}


- (NSArray *) getBoundingBoxesIn:(HogFeature *)imageHog forPyramid:(int)pyramidLevel forIndex:(int)imageHogIndex
{
    int blocks[2] = {imageHog.numBlocksY, imageHog.numBlocksX};
    
    int convolutionSize[2];
    
    convolutionSize[0] = blocks[0] - _sizesP[0] + 1;
    convolutionSize[1] = blocks[1] - _sizesP[1] + 1;
    if ((convolutionSize[0]<=0) || (convolutionSize[1]<=0))
        return NULL;
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:convolutionSize[0]*convolutionSize[1]];
    double *c = (double *) calloc(convolutionSize[0]*convolutionSize[1],sizeof(double)); //initialize the convolution result
    
    // convolve and add the result
    for (int f = 0; f < _sizesP[2]; f++){
        
        double *dst = c;
        double *A_src = imageHog.features + f*blocks[0]*blocks[1]; //Select the block of features to do the convolution with
        double *B_src = _weightsP + f*_sizesP[0]*_sizesP[1];
        
        // convolute and add the results to dst
        [ConvolutionHelper convolution:dst matrixA:A_src :blocks matrixB:B_src :_sizesP];
        //[ConvolutionHelper convolutionWithVDSP:dst matrixA:A_src :blocks matrixB:B_src :templateSize];
        
    }
    
    //detect max in the convolution
    double bias = _weightsP[_sizesP[0]*_sizesP[1]*_sizesP[2]];
    for (int x = 0; x < convolutionSize[1]; x++) {
        for (int y = 0; y < convolutionSize[0]; y++) {
            
            BoundingBox *p = [[BoundingBox alloc] init];
            p.score = (*(c + x*convolutionSize[0] + y) - bias);
            if( p.score > -1 ){
                
                p.xmin = (double)(x + 1)/((double)blocks[1] + 2);
                p.xmax = (double)(x + 1)/((double)blocks[1] + 2) + ((double)_sizesP[1]/((double)blocks[1] + 2));
                p.ymin = (double)(y + 1)/((double)blocks[0] + 2);
                p.ymax = (double)(y + 1)/((double)blocks[0] + 2) + ((double)_sizesP[0]/((double)blocks[0] + 2));
                p.pyramidLevel = pyramidLevel;
                p.targetClass = [self.targetClasses componentsJoinedByString:@"+"];
                
                //save the location and image hog for the later feature extraction during the learning
                if(_isLearning){
                    p.locationOnImageHog = CGPointMake(x, y);
                    p.imageHogIndex = imageHogIndex;
                }
                [result addObject:p];
            }
        }
    }
    free(c);
    return result;
}


-(void) addExample:(BoundingBox *)p to:(TrainingSet *)trainingSet
{
    int index = _numberOfTrainingExamples;
    HogFeature *imageHog = [_imagesHogPyramid objectAtIndex:p.imageHogIndex];
    
    //label
    _trainingImageLabels[index] = p.label;
    
    //features
    int boundingBoxPosition = p.locationOnImageHog.y + p.locationOnImageHog.x*imageHog.numBlocksY;
    for(int f=0; f<_sizesP[2]; f++)
        for(int i=0; i<_sizesP[1]; i++)
            for(int j=0; j<_sizesP[0]; j++){
                int sweeping1 = j + i*_sizesP[0] + f*_sizesP[0]*_sizesP[1];
                int sweeping2 = j + i*imageHog.numBlocksY + f*imageHog.numBlocksX*imageHog.numBlocksY;
                _trainingImageFeatures[index*_numOfFeatures + sweeping1] = (float) imageHog.features[boundingBoxPosition + sweeping2];
            }

    
    _numberOfTrainingExamples++;
}



- (void) getBoundingBoxesForTrainingSet:(TrainingSet *)trainingSet
{
    
    // Constructs the training set of features.
    // Given real images and Bounding boxes, it extracts cropped images
    // representing positive an negative examples.
    // The cropped images are extracted using the detector and classified (as positive or negative)
    // depending on the overlapping area with the ground truth (GT) bounding boxes
    __block int positives = 0;
    _numberOfTrainingExamples = _numSupportVectors;
    
    //concurrent adding examples for the different images
    dispatch_queue_t trainingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(trainingSet.images.count, trainingQueue, ^(size_t i) {
        if(!_isTrainCancelled){
            UIImage *image = [trainingSet.images objectAtIndex:i];
            
            //run the detector on the current image
            NSArray *newBoundingBoxes = [self detect:image minimumThreshold:-1 pyramids:10 usingNms:NO deviceOrientation:UIImageOrientationUp learningImageIndex:i];
            
            dispatch_sync(dispatch_get_main_queue(),^{[self.delegate sendMessage:[NSString stringWithFormat:@"New bb obtained for image %zd: %d", i, newBoundingBoxes.count]];});
            
            //max negative bounding boxes detected per image
            int quota = MAX_QUOTA;
            NSArray *selectedGT = trainingSet.groundTruthBoundingBoxes;
            NSMutableArray *aux = [selectedGT mutableCopy];
            
            for(BoundingBox *newBB in newBoundingBoxes){
                
                BOOL isNegative = NO;
                BOOL GTFound = NO;
                
                for(BoundingBox *groundTruthBB in selectedGT){
                    if(groundTruthBB.imageIndex == i){
                        
                        GTFound = YES;
                        double overlapArea = [newBB fractionOfAreaOverlappingWith:groundTruthBB];
                        
                        if (overlapArea > 0.8 && overlapArea<1){
                            newBB.label = 1;
                            isNegative = NO;
                            if(_numberOfTrainingExamples+1 < MAX_NUMBER_EXAMPLES){
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    [self addExample:newBB to:trainingSet];
                                    positives++;
                                });
                            }else NSLog(@"Training Buffer FULL!!");
                        }else if(overlapArea < 0.25 && quota>0) isNegative = YES;
                    }else [aux removeObject:groundTruthBB];
                }
                
                selectedGT = aux;
                if((isNegative || (GTFound == NO)) && quota>0){
                    quota--;
                    newBB.label = -1;
                    dispatch_sync(dispatch_get_main_queue(), ^{[self addExample:newBB to:trainingSet];});
                }
            }
        }
    });
    dispatch_release(trainingQueue);
        
    [self.delegate sendMessage:[NSString stringWithFormat:@"added:%d positives", positives]];
    self.numberOfPositives = [NSNumber numberWithInt:positives];
}

-(void) trainSVMAndGetWeights
{
    [self.delegate sendMessage:[NSString stringWithFormat:@"Number of Training Examples: %d", _numberOfTrainingExamples]];
    int positives=0;
    
    Mat labelsMat(_numberOfTrainingExamples,1,CV_32FC1, _trainingImageLabels);
    Mat trainingDataMat(_numberOfTrainingExamples, _numOfFeatures, CV_32FC1, _trainingImageFeatures);
    //std::cout << trainingDataMat << std::endl; //output learning matrix
    
    // Set up SVM's parameters
    CvSVMParams params;
    params.svm_type    = CvSVM::C_SVC;
    params.kernel_type = CvSVM::LINEAR;
    params.term_crit   = cvTermCriteria(CV_TERMCRIT_ITER, 1000, 1e-6);
    
    CvSVM SVM;
    SVM.train(trainingDataMat, labelsMat, Mat(), Mat(), params);
    
    //update weights and store the support vectors
    _numSupportVectors = SVM.get_support_vector_count();
    _numberOfTrainingExamples = _numSupportVectors;
    const CvSVMDecisionFunc *dec = SVM.decision_func;
    for(int i=0; i<_numOfFeatures+1; i++) _weightsP[i] = 0.0;
    
    for (int i=0; i<_numSupportVectors; i++){
        float alpha = dec[0].alpha[i];
        const float *supportVector = SVM.get_support_vector(i);
        float *sv_aux = (float *) malloc(_numOfFeatures*sizeof(float));
        for(int j=0;j<_numOfFeatures;j++) //const float* to float*
            sv_aux[j] = supportVector[j];
        
        // Get the current label of the supportvector
        Mat supportVectorMat(_numOfFeatures,1,CV_32FC1, sv_aux);
        _trainingImageLabels[i] = SVM.predict(supportVectorMat);
        if(_trainingImageLabels[i]==1) positives++;
        free(sv_aux);
        //NSLog(@"label: %f   alpha: %f \n", _trainingImageLabels[i], alpha);
        
        for(int j=0;j<_numOfFeatures;j++){
            // add to get the svm weights
            _weightsP[j] -= (double) alpha * supportVector[j];
            
            //store the support vector as the first features
            _trainingImageFeatures[i*_numOfFeatures + j] = supportVector[j];
        }
    }
    _weightsP[_numOfFeatures] = - (double) dec[0].rho; // The sign of the bias and rho have opposed signs.
    self.numberOfPositives = [[NSNumber alloc] initWithInt:positives];
    [self.delegate sendMessage:[NSString stringWithFormat:@"bias: %f", _weightsP[_numOfFeatures]]];
}

-(double) computeDifferenceWithLastWeights:(double *) weightsPLast
{
    _diff=0.0;
    
    double norm=0, normLast=0;
    for(int i=0; i<_sizesP[0]*_sizesP[1]*_sizesP[2] + 1; i++){
        norm += _weightsP[i]*_weightsP[i];
        normLast += weightsPLast[i]*weightsPLast[i];
    }
    norm = sqrt(norm);
    normLast = normLast!=0 ? sqrt(normLast):1;
    

    for(int i=0; i<_sizesP[0]*_sizesP[1]*_sizesP[2] + 1; i++){
        _diff += (_weightsP[i]/norm - weightsPLast[i]/normLast)*(_weightsP[i]/norm - weightsPLast[i]/normLast);
        weightsPLast[i] = _weightsP[i];
    }
    
    [self.delegate sendMessage:[NSString stringWithFormat:@"norms: %f, %f", norm, normLast]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"difference: %f", sqrt(_diff)]];
    
    return sqrt(_diff);
}

- (void) printListHogFeatures:(float *) listOfHogFeaturesFloat
{
    //Print unoriented hog features for debugging purposes
    for(int y=0; y<_sizesP[0]; y++){
        for(int x=0; x<_sizesP[1]; x++){
            for(int f = 18; f<27; f++){
                printf("%f ", listOfHogFeaturesFloat[y + x*7 + f*7*5]);
                //                if(f==17 || f==26) printf("  |  ");
            }
            printf("\n");
        }
        printf("\n*************************************************************************\n");
    }
}

@end
