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

//training results
#define SUCCESS 1
#define INTERRUPTED 2 //and not trained
#define FAIL 0

@interface Detector ()
{
    int numOfFeatures;
    int numSupportVectors;
    float diff;
    int levelsPyramid[10]; //how many bb of each level do we obtain
}

@property BOOL isLearning;

//pyramid limits for detection in execution
@property int iniPyramid;
@property int finPyramid;

//detector buffer (when training)
@property (strong, nonatomic) NSMutableArray *receivedImageIndex;
@property (strong, nonatomic) NSMutableArray *imagesHogPyramid;

//store the weights of the last iteration for convergence
@property double *weightsPLast;

//Show just the histogram features for debugging purposes
- (void) showOrientationHistogram;

//make the convolution of the detector with the image and return de detected bounding boxes
- (NSArray *) getBoundingBoxesIn:(HogFeature *)imageHog forPyramid:(int)pyramidLevel forIndex:(int)imageHogIndex;

//add a selected bounding box (its correspondent hog features) to the training buffer
-(void) addExample:(BoundingBox *)p to:(TrainingSet *)trainingSet;


-(double) computeDifferenceOfWeights;

@end


@implementation Detector


@synthesize weightsP = _weightsP;
@synthesize sizesP = _sizesP;
@synthesize maxHog = _maxHog;
@synthesize delegate = _delegate;
@synthesize isLearning = _isLearning;
@synthesize iniPyramid = _iniPyramid;
@synthesize finPyramid = _finPyramid;
@synthesize receivedImageIndex = _receivedImageIndex;
@synthesize imagesHogPyramid = _imagesHogPyramid;

@synthesize weights = _weights;
@synthesize sizes = _sizes;
@synthesize name = _name;
@synthesize targetClasses = _targetClasses;
@synthesize numberSV = _numberSV;
@synthesize numberOfPositives = _numberOfPositives;
@synthesize precisionRecall = _precisionRecall;



#pragma mark -
#pragma mark Getters and Setters

- (NSNumber *) detectionThreshold
{
    if(!_detectionThreshold) _detectionThreshold = [NSNumber numberWithFloat:0.5];
    return _detectionThreshold;
}


#pragma mark -
#pragma mark Public Methods


- (id) initWithTemplateWeights:(double *)templateWeights
{
    for(int i=0; i<10;i++) levelsPyramid[i] = 0;

    if(self = [super init]){
        self.sizesP = (int *) malloc(3*sizeof(int));
        self.sizesP[0] = (int) templateWeights[0];
        self.sizesP[1] = (int) templateWeights[1];
        self.sizesP[2] = (int) templateWeights[2];
        
        int numberOfSvmWeights = self.sizesP[0]*self.sizesP[1]*self.sizesP[2] + 1; //+1 for the bias
        self.weightsP = (double *) malloc(numberOfSvmWeights*sizeof(double));
        for(int i=0; i<numberOfSvmWeights; i++) 
            self.weightsP[i] = templateWeights[3 + i];
    }
    return self;
}

- (id) init
{
    if (self = [super init]) {
        
        //dummy initialization to be replaced during the training
        self.sizesP = (int *) malloc(3*sizeof(int));
        self.sizesP[0] = 1;
        self.sizesP[1] = 1;
        self.sizesP[2] = 1;
        
        self.weightsP = (double *) malloc(sizeof(double));
        self.weightsP[0] = 0;
    }
    
    return self;
}


- (void) printListHogFeatures:(float *) listOfHogFeaturesFloat
{
    //Print unoriented hog features for debugging purposes
    for(int y=0; y<self.sizesP[0]; y++){
        for(int x=0; x<self.sizesP[1]; x++){
            for(int f = 18; f<27; f++){
                printf("%f ", listOfHogFeaturesFloat[y + x*7 + f*7*5]);
//                if(f==17 || f==26) printf("  |  ");
            }
            printf("\n");
        }
        printf("\n*************************************************************************\n");
    }
}

- (int) train:(TrainingSet *) trainingSet;
{
    NSDate *start = [NSDate date]; //to compute the learning time.
    free(self.weightsP);
    self.isLearning = YES;
    
    //array initialization
    self.imageListAux = [[NSMutableArray alloc] init];
    self.imagesHogPyramid = [[NSMutableArray alloc] init];
    for (int i = 0; i < trainingSet.images.count*10; ++i)
        [self.imagesHogPyramid addObject:[NSNull null]];
    self.receivedImageIndex = [[NSMutableArray alloc] init];
    
    //set hog dimension according to the max Hog set in user preferences
    float ratio;
    if(trainingSet.templateSize.height > trainingSet.templateSize.width){
        ratio = trainingSet.templateSize.width/trainingSet.templateSize.height;
        self.sizesP[0] = self.maxHog; //set in user preferences
        self.sizesP[1] = round(self.sizesP[0]*ratio);

    }else{
        ratio = trainingSet.templateSize.height/trainingSet.templateSize.width;
        self.sizesP[1] = self.maxHog;
        self.sizesP[0] = round(self.sizesP[1]*ratio);
    }
    self.sizesP[2] = 31;
    
    //scalefactor for detection. Used to ajust hog size with images resolution
    self.scaleFactor = [NSNumber numberWithDouble:self.maxHog*pixelsPerHogCell*sqrt(ratio/trainingSet.areaRatio)];
    numOfFeatures = self.sizesP[0]*self.sizesP[1]*self.sizesP[2];
    
    [self.delegate sendMessage:[NSString stringWithFormat:@"Hog features: %d %d %d for ratio:%f", self.sizesP[0],self.sizesP[1],self.sizesP[2], ratio]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"area ratio: %f", trainingSet.areaRatio]];
    
    //define buffer sizes
    //TODO: max size for the buffers
    trainingSet.imageFeatures = (float *) malloc(MAX_NUMBER_EXAMPLES*numOfFeatures*sizeof(float));
    trainingSet.labels = (float *) malloc(MAX_NUMBER_EXAMPLES*sizeof(float));
    
    //convergence loop
    self.weightsP = (double *) calloc((numOfFeatures+1),sizeof(double));
    for(int i=0; i<numOfFeatures+1;i++) self.weightsP[i] = 1;
    self.weightsPLast = (double *) calloc((numOfFeatures+1),sizeof(double));
    diff = 1;
    int iter = 0;
    numSupportVectors=0;
    BOOL firstTimeError = YES;
    
    while(diff > STOP_CRITERIA && iter<10 && !self.trainCancelled){

        [self.delegate sendMessage:[NSString stringWithFormat:@"\n******* Iteration %d ******", iter]];
        
        //Get Bounding Boxes from detection
        [self getBoundingBoxesForTrainingWith:trainingSet];
        
        //The first time that not enough positive or negative bb have been generated, try to unify all the sizes of the bounding boxes. This solve the problem in most of the cases. However if still not solved, through an error saying not possible training done due to the ground truth bouning boxes shape.
        if(self.numberOfPositives.intValue < 2 || self.numberOfPositives.intValue == trainingSet.numberOfTrainingExamples){
            if(firstTimeError){
                [trainingSet unifyGroundTruthBoundingBoxes];
                firstTimeError = NO;
                continue;
            }else return FAIL;
        }
        
        //Train the SVM, update weights and store support vectors and labels
        [self trainSVMAndGetWeights:trainingSet];
        
        diff = [self computeDifferenceOfWeights];
        iter++;
        if(iter!=1) [self.delegate updateProgress:STOP_CRITERIA/diff];
    }
    
    
    if(self.trainCancelled) [self.delegate sendMessage:@"\n TRAINING INTERRUPTED \n"];
    if(iter == 0) return INTERRUPTED; 

    
    //update information about the detector
    self.numberSV = [NSNumber numberWithInt:numSupportVectors];
    self.timeLearning = [NSNumber numberWithDouble:-[start timeIntervalSinceNow]];
    
    //See the results on training set
    [self.delegate updateProgress:1];
    self.isLearning = NO;
    self.imagesHogPyramid = nil;
    self.receivedImageIndex = nil;
    free(self.weightsPLast);
    free(trainingSet.imageFeatures);
    free(trainingSet.labels);
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
    double initialScale = self.scaleFactor.doubleValue/sqrt(image.size.width*image.size.width);
    if(UIDeviceOrientationIsLandscape(orientation)) initialScale = initialScale * 1.3;
    double scale = pow(2, 1.0/SCALES_PER_OCTAVE);

    //Pyramid limits
    if(self.finPyramid == 0) self.finPyramid = numberPyramids;
    
    //locate pyramids already calculated in the buffer
    BOOL found=NO;
    if(self.isLearning){
        
        //pyramid limits
        self.iniPyramid = 0; self.finPyramid = numberPyramids;
        
        //Locate pyramids in buffer
        found = YES;
        if([self.receivedImageIndex indexOfObject:[NSNumber numberWithInt:imageIndex]] == NSNotFound || self.receivedImageIndex.count == 0){
            [self.receivedImageIndex addObject:[NSNumber numberWithInt:imageIndex]];
            found = NO;
        }
    }
    
    dispatch_queue_t pyramidQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    UIImage *im = [image scaleImageTo:initialScale/pow(scale,self.iniPyramid)];
    dispatch_apply(self.finPyramid - self.iniPyramid, pyramidQueue, ^(size_t i) {
        HogFeature *imageHog;
        int imageHogIndex = 0;
        float scaleLevel = pow(1.0/scale, i);
        if(!found){
            imageHog = [[im scaleImageTo:scaleLevel] obtainHogFeatures];
//            NSLog(@"Pyramid %zd, numblocs x:%d, numblocks y:%d", i, imageHog.numBlocksX, imageHog.numBlocksY);
            
            if(self.isLearning){
                imageHogIndex = imageIndex*numberPyramids + i + self.iniPyramid;
                [self.imagesHogPyramid replaceObjectAtIndex:imageHogIndex withObject:imageHog];
            }
        }else{
            imageHogIndex = (imageIndex*numberPyramids + i + self.iniPyramid);
            imageHog = (HogFeature *)[self.imagesHogPyramid objectAtIndex:imageHogIndex];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [candidateBoundingBoxes addObjectsFromArray:[self getBoundingBoxesIn:imageHog forPyramid:i+self.iniPyramid forIndex:imageHogIndex]];
        });
    });
    dispatch_release(pyramidQueue);
    
    
    //sort array of bounding boxes by score
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *candidateBoundingBoxesSorted = [candidateBoundingBoxes sortedArrayUsingDescriptors:sortDescriptors];
    
    NSArray *nmsArray = candidateBoundingBoxesSorted;
    if(useNms) nmsArray = [ConvolutionHelper nms:candidateBoundingBoxesSorted maxOverlapArea:0.25 minScoreThreshold:detectionThreshold]; 

    if(!self.isLearning && nmsArray.count > 0){
        //get the level of the maximum score bb
        int level = [(BoundingBox*)[nmsArray objectAtIndex:0] pyramidLevel];
        self.iniPyramid = level-1 > -1 ? level - 1 : 0;
        self.finPyramid = level+2 < numberPyramids ? level+2 : numberPyramids;
    }else{
        self.iniPyramid = 0;
        self.finPyramid = numberPyramids;
    }
    
    // Change the resulting orientation of the bounding boxes if the phone orientation requires it
    if(!self.isLearning && UIInterfaceOrientationIsLandscape(orientation)){
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
    dispatch_apply(self.finPyramid - self.iniPyramid, pyramidQueue, ^(size_t i) {
        if([[pyramid.hogFeatures objectAtIndex:i+self.iniPyramid] isKindOfClass:[HogFeature class]]){
            __block HogFeature *imageHog;
            dispatch_sync(dispatch_get_main_queue(), ^{
                imageHog = [pyramid.hogFeatures objectAtIndex:i+self.iniPyramid];
            });
            candidatesForLevel = [self getBoundingBoxesIn:imageHog forPyramid:i+self.iniPyramid forIndex:0];
        }else{
            NSLog(@"Error trying to retrieve pyramid %zd, not the correct class",i+self.iniPyramid);
            NSLog(@"Obtained class: %@", [[pyramid.hogFeatures objectAtIndex:i+self.iniPyramid] class]);
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
        self.iniPyramid = level-1 > -1 ? level - 1 : 0;
        self.finPyramid = level+2 < pyramid.numPyramids ? level+2 : pyramid.numPyramids;
    }else{
        self.iniPyramid = 0;
        self.finPyramid = pyramid.numPyramids;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        for(int i=self.iniPyramid;i<self.finPyramid;i++)
            [pyramid.levelsToCalculate addObject:[NSNumber numberWithInt:i]];
    });

    
    // Change the resulting orientation of the bounding boxes if the phone orientation requires it
    if(!self.isLearning && UIInterfaceOrientationIsLandscape(orientation)){
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
    
    self.isLearning = YES;
    //TODO: not multiimage
    NSLog(@"Detection threshold: %f", detectionThreshold);
    int tp=0, fp=0, fn=0;// tn=0;
    for(BoundingBox *groundTruthBoundingBox in testSet.groundTruthBoundingBoxes){
        bool found = NO;
        UIImage *selectedImage = [testSet.images objectAtIndex:groundTruthBoundingBox.imageIndex];
        NSArray *detectedBoundingBoxes = [self detect:selectedImage minimumThreshold:detectionThreshold pyramids:10 usingNms:YES deviceOrientation:UIImageOrientationUp learningImageIndex:groundTruthBoundingBox.imageIndex];
        NSLog(@"For image %d generated %d detecting boxes", groundTruthBoundingBox.imageIndex, detectedBoundingBoxes.count);
        for(BoundingBox *detectedBoundingBox in detectedBoundingBoxes)
            if ([detectedBoundingBox fractionOfAreaOverlappingWith:groundTruthBoundingBox]>0.5){
                tp++;
                found = YES;
            }else fp++;
        
        if(!found) fn++;
        NSLog(@"tp at image %d: %d", groundTruthBoundingBox.imageIndex, tp);
        NSLog(@"fp at image %d: %d", groundTruthBoundingBox.imageIndex, fp);
        NSLog(@"fn at image %d: %d", groundTruthBoundingBox.imageIndex, fn);
    }

    [self.delegate sendMessage:[NSString stringWithFormat:@"PRECISION: %f", tp*1.0/(tp+fp)]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"RECALL: %f", tp*1.0/(tp+fn)]];
    self.precisionRecall = [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:tp*1.0/(tp+fp)],[NSNumber numberWithDouble:tp*1.0/(tp+fn)] ,nil];
    
    self.isLearning = NO;
}


#pragma mark -
#pragma mark Encoding

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
        
        self.sizesP = (int *) malloc(3*sizeof(int));
        self.sizesP[0] = [(NSNumber *) [self.sizes objectAtIndex:0] intValue];
        self.sizesP[1] = [(NSNumber *) [self.sizes objectAtIndex:1] intValue];
        self.sizesP[2] = [(NSNumber *) [self.sizes objectAtIndex:2] intValue];
        
        int numberOfSvmWeights = self.sizesP[0]*self.sizesP[1]*self.sizesP[2] + 1; //+1 for the bias
        
        self.weightsP = (double *) malloc(numberOfSvmWeights*sizeof(double));
        for(int i=0; i<numberOfSvmWeights; i++)
            self.weightsP[i] = [(NSNumber *) [self.weights objectAtIndex:i] doubleValue];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    self.sizes = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithInt:self.sizesP[0]],
                    [NSNumber numberWithInt:self.sizesP[1]],
                    [NSNumber numberWithInt:self.sizesP[2]], nil];
    
    int numberOfSvmWeights = self.sizesP[0]*self.sizesP[1]*self.sizesP[2] + 1; //+1 for the bias
    
    self.weights = [[NSMutableArray alloc] initWithCapacity:numberOfSvmWeights];
    for(int i=0; i<numberOfSvmWeights; i++)
        [self.weights addObject:[NSNumber numberWithDouble:self.weightsP[i]]];
    
    
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


#pragma mark -
#pragma mark Private methods

- (void) showOrientationHistogram
{
    double *histogram = (double *) calloc(18,sizeof(double));
    for(int x = 0; x<self.sizesP[1]; x++)
        for(int y=0; y<self.sizesP[0]; y++)
            for(int f=18; f<27; f++)
                histogram[f-18] += self.weightsP[y + x*self.sizesP[0] + f*self.sizesP[0]*self.sizesP[1]];
    
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
    
    convolutionSize[0] = blocks[0] - self.sizesP[0] + 1;
    convolutionSize[1] = blocks[1] - self.sizesP[1] + 1;
    if ((convolutionSize[0]<=0) || (convolutionSize[1]<=0))
        return NULL;
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:convolutionSize[0]*convolutionSize[1]];
    double *c = (double *) calloc(convolutionSize[0]*convolutionSize[1],sizeof(double)); //initialize the convolution result
    
    // convolve and add the result
    for (int f = 0; f < self.sizesP[2]; f++){
        
        double *dst = c;
        double *A_src = imageHog.features + f*blocks[0]*blocks[1]; //Select the block of features to do the convolution with
        double *B_src = self.weightsP + f*self.sizesP[0]*self.sizesP[1];
        
        // convolute and add the results to dst
        [ConvolutionHelper convolution:dst matrixA:A_src :blocks matrixB:B_src :self.sizesP];
        //[ConvolutionHelper convolutionWithVDSP:dst matrixA:A_src :blocks matrixB:B_src :templateSize];
        
    }
    
    //detect max in the convolution
    double bias = self.weightsP[self.sizesP[0]*self.sizesP[1]*self.sizesP[2]];
    for (int x = 0; x < convolutionSize[1]; x++) {
        for (int y = 0; y < convolutionSize[0]; y++) {
            
            BoundingBox *p = [[BoundingBox alloc] init];
            p.score = (*(c + x*convolutionSize[0] + y) - bias);
            if( p.score > -1 ){
//                NSLog(@"Image hog size: %d x %d", blocks[1], blocks[0]);
//                NSLog(@"Template hog size: %d x %d", self.sizesP[1], self.sizesP[1]);
                
                p.xmin = (double)(x + 1)/((double)blocks[1] + 2);
                p.xmax = (double)(x + 1)/((double)blocks[1] + 2) + ((double)self.sizesP[1]/((double)blocks[1] + 2));
                p.ymin = (double)(y + 1)/((double)blocks[0] + 2);
                p.ymax = (double)(y + 1)/((double)blocks[0] + 2) + ((double)self.sizesP[0]/((double)blocks[0] + 2));
                p.pyramidLevel = pyramidLevel;
                p.targetClass = [self.targetClasses componentsJoinedByString:@"+"];
                
//                NSLog(@"Box obtained: %@", p);
                
                //save the location and image hog for the later feature extraction during the learning
                if(self.isLearning){
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
    int index = trainingSet.numberOfTrainingExamples;
    HogFeature *imageHog = [self.imagesHogPyramid objectAtIndex:p.imageHogIndex];
    
    //label
    trainingSet.labels[index] = p.label;
    
    //features
    int boundingBoxPosition = p.locationOnImageHog.y + p.locationOnImageHog.x*imageHog.numBlocksY;
    for(int f=0; f<self.sizesP[2]; f++)
        for(int i=0; i<self.sizesP[1]; i++)
            for(int j=0; j<self.sizesP[0]; j++){
                int sweeping1 = j + i*self.sizesP[0] + f*self.sizesP[0]*self.sizesP[1];
                int sweeping2 = j + i*imageHog.numBlocksY + f*imageHog.numBlocksX*imageHog.numBlocksY;
                trainingSet.imageFeatures[index*numOfFeatures + sweeping1] = (float) imageHog.features[boundingBoxPosition + sweeping2];
            }

    
    trainingSet.numberOfTrainingExamples++;
}



- (void) getBoundingBoxesForTrainingWith:(TrainingSet *) trainingSet
{
    __block int positives = 0;
    trainingSet.numberOfTrainingExamples = numSupportVectors;
    
    //concurrent adding examples for the different images
    dispatch_queue_t trainingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(trainingSet.images.count, trainingQueue, ^(size_t i) {
        if(!self.trainCancelled){
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
                            if(trainingSet.numberOfTrainingExamples+1 < MAX_NUMBER_EXAMPLES){
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

-(void) trainSVMAndGetWeights:(TrainingSet *)trainingSet
{
    [self.delegate sendMessage:[NSString stringWithFormat:@"Number of Training Examples: %d", trainingSet.numberOfTrainingExamples]];
    int positives=0;
    
    Mat labelsMat(trainingSet.numberOfTrainingExamples,1,CV_32FC1, trainingSet.labels);
    Mat trainingDataMat(trainingSet.numberOfTrainingExamples, numOfFeatures, CV_32FC1, trainingSet.imageFeatures);
    //std::cout << trainingDataMat << std::endl; //output learning matrix
    
    // Set up SVM's parameters
    CvSVMParams params;
    params.svm_type    = CvSVM::C_SVC;
    params.kernel_type = CvSVM::LINEAR;
    params.term_crit   = cvTermCriteria(CV_TERMCRIT_ITER, 1000, 1e-6);
    
    CvSVM SVM;
    SVM.train(trainingDataMat, labelsMat, Mat(), Mat(), params);
    
    //update weights and store the support vectors
    numSupportVectors = SVM.get_support_vector_count();
    trainingSet.numberOfTrainingExamples = numSupportVectors;
    const CvSVMDecisionFunc *dec = SVM.decision_func;
    for(int i=0; i<numOfFeatures+1;i++) self.weightsP[i] = 0.0;
    
    NSLog(@"Num of support vectors: %d\n", numSupportVectors);
    
    for (int i=0; i<numSupportVectors; i++){
        float alpha = dec[0].alpha[i];
        const float *supportVector = SVM.get_support_vector(i);
        float *sv_aux = (float *) malloc(numOfFeatures*sizeof(float));
        for(int j=0;j<numOfFeatures;j++) //const float* to float*
            sv_aux[j] = supportVector[j];
        
        // Get the current label of the supportvector
        Mat supportVectorMat(numOfFeatures,1,CV_32FC1, sv_aux);
        trainingSet.labels[i] = SVM.predict(supportVectorMat);
        if(trainingSet.labels[i]==1) positives++;
        free(sv_aux);
        NSLog(@"label: %f   alpha: %f \n", trainingSet.labels[i], alpha);
        
        for(int j=0;j<numOfFeatures;j++){
            // add to get the svm weights
            self.weightsP[j] -= (double) alpha * supportVector[j];
            
            //store the support vector as the first features
            trainingSet.imageFeatures[i*numOfFeatures + j] = supportVector[j];
        }
    }
    self.weightsP[numOfFeatures] = - (double) dec[0].rho; // The sign of the bias and rho have opposed signs.
    self.numberOfPositives = [[NSNumber alloc] initWithInt:positives];
    [self.delegate sendMessage:[NSString stringWithFormat:@"bias: %f", self.weightsP[numOfFeatures]]];
}

-(double) computeDifferenceOfWeights
{
    diff=0.0;
    
    double norm=0, normLast=0;
    for(int i=0; i<self.sizesP[0]*self.sizesP[1]*self.sizesP[2] + 1; i++){
        norm += self.weightsP[i]*self.weightsP[i];
        normLast += self.weightsPLast[i]*self.weightsPLast[i];
    }
    norm = sqrt(norm);
    normLast = normLast!=0 ? sqrt(normLast):1;
    

    for(int i=0; i<self.sizesP[0]*self.sizesP[1]*self.sizesP[2] + 1; i++){
        diff += (self.weightsP[i]/norm - self.weightsPLast[i]/normLast)*(self.weightsP[i]/norm - self.weightsPLast[i]/normLast);
        self.weightsPLast[i] = self.weightsP[i];
    }
    
    [self.delegate sendMessage:[NSString stringWithFormat:@"norms: %f, %f", norm, normLast]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"difference: %f", sqrt(diff)]];
    
    return sqrt(diff);
}

@end
