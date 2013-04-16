//
//  Classifier.m
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 28/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#include <opencv2/core/core.hpp>
#include <opencv2/ml/ml.hpp>
#include <stdlib.h>

#import "Classifier.h"
#import "UIImage+HOG.h"
#import "UIImage+Resize.h"
#import "ConvolutionHelper.h"

using namespace cv;

#define MAX_QUOTA 100 //max negative examples (bb) per iteration
#define MAX_NUMBER_EXAMPLES (MAX_QUOTA + 200)*20 //max number of examples in buffer, (500neg + 200pos)*20images
#define STOP_CRITERIA 0.05 
#define MAX_IMAGE_SIZE 300.0



@interface Classifier ()
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
@property (strong, nonatomic) NSMutableArray *receivedImages;
@property (strong, nonatomic) NSMutableArray *imagesHogPyramid;

//store the weights of the last iteration for convergence
@property double *weightsPLast;

//Show just the histogram features for debugging purposes
- (void) showOrientationHistogram;

//make the convolution of the classifier with the image and return de detected bounding boxes
- (NSArray *) getBoundingBoxesIn:(HogFeature *)imageHog forPyramid:(int)pyramidLevel forIndex:(int)imageHogIndex;

//add a selected bounding box to the training buffer
-(void) addExample:(BoundingBox *)p to:(TrainingSet *)trainingSet;


-(double) computeDifferenceOfWeights;

@end


@implementation Classifier


@synthesize weightsP = _weightsP;
@synthesize sizesP = _sizesP;
@synthesize delegate = _delegate;
@synthesize isLearning = _isLearning;
@synthesize iniPyramid = _iniPyramid;
@synthesize finPyramid = _finPyramid;
@synthesize receivedImages = _receivedImages;
@synthesize imagesHogPyramid = _imagesHogPyramid;

@synthesize weights = _weights;
@synthesize sizes = _sizes;
@synthesize name = _name;
@synthesize targetClass = _targetClass;
@synthesize numberSV = _numberSV;
@synthesize numberOfPositives = _numberOfPositives;
@synthesize precisionRecall = _precisionRecall;




#pragma mark
#pragma mark - Public Methods


- (id) initWithTemplateWeights:(double *)templateWeights
{
    for(int i=0; i<10;i++)
        levelsPyramid[i] =0;
        
        
    if(self = [super init])
    {
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
        self.sizesP = (int *) malloc(3*sizeof(int));
        self.sizesP[0] = 1;
        self.sizesP[1] = 1;
        self.sizesP[2] = 1;
        
        //dummy initialization to be replaced during the training
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

- (void) train:(TrainingSet *) trainingSet;
{
    NSDate *start = [NSDate date];
    free(self.weightsP);
    self.isLearning = YES;
    self.imageListAux = [[NSMutableArray alloc] init];
    self.imagesHogPyramid = [[NSMutableArray alloc] init];
    self.receivedImages = [[NSMutableArray alloc] init];
    
    
    // Get the template size and get hog feautures dimension
    float ratio = trainingSet.templateSize.width/trainingSet.templateSize.height;
    self.sizesP[0] = round(40*trainingSet.areaRatio + 4); //Determined empirically to ajust the size of the template according to the size in the training set
    self.sizesP[1] = round(self.sizesP[0]*ratio);
    self.sizesP[2] = 31;
    numOfFeatures = self.sizesP[0]*self.sizesP[1]*self.sizesP[2];
    [self.delegate sendMessage:[NSString stringWithFormat:@"Hog features: %d %d %d for ratio:%f", self.sizesP[0],self.sizesP[1],self.sizesP[2], ratio]];
    [self.delegate sendMessage:[NSString stringWithFormat:@"area ratio: %f", trainingSet.areaRatio]];
    
    //TODO: max size for the buffers
    trainingSet.imageFeatures = (float *) malloc(MAX_NUMBER_EXAMPLES*numOfFeatures*sizeof(float));
    trainingSet.labels = (float *) malloc(MAX_NUMBER_EXAMPLES*sizeof(float));
    
    //convergence loop
    self.weightsP = (double *) calloc((numOfFeatures+1),sizeof(double));
    for(int i=0; i<numOfFeatures+1;i++) self.weightsP[i]=1;
    self.weightsPLast = (double *) calloc((numOfFeatures+1),sizeof(double));
    diff = 1;
    int iter = 0;
    numSupportVectors=0;
    
    while(diff > STOP_CRITERIA && iter<10){

        [self.delegate sendMessage:[NSString stringWithFormat:@"\n******* Iteration %d ******", iter++]];
        
        //Get Bounding Boxes from detection
        [self getBoundingBoxesForTrainingWith:trainingSet];
        
        //Train the SVM, update weights and store support vectors and labels
        [self trainSVMAndGetWeights:trainingSet];
        
        diff = [self computeDifferenceOfWeights];
        if(iter!=1) [self.delegate updateProgress:STOP_CRITERIA/diff];
    }
    
    //update information about the classifier
    self.numberSV = [NSNumber numberWithInt:numSupportVectors];
    self.timeLearning = [NSNumber numberWithDouble:-[start timeIntervalSinceNow]];
    
    //See the results on training set
    [self.delegate updateProgress:1];
    [self testOnSet:trainingSet atThresHold:0];
    self.isLearning = NO;
    self.imagesHogPyramid = nil;
    free(self.weightsPLast);
    free(trainingSet.imageFeatures);
    free(trainingSet.labels);
}


- (NSArray *) detect:(UIImage *)image
    minimumThreshold:(double) detectionThreshold
            pyramids:(int)numberPyramids
            usingNms:(BOOL)useNms
   deviceOrientation:(int)orientation
{
    
    NSMutableArray *candidateBoundingBoxes = [[NSMutableArray alloc] init];
    
    //rotate image depending on the orientation
    if(!self.isLearning && UIDeviceOrientationIsLandscape(orientation))
        image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation: UIImageOrientationUp];

    double initialScale = MAX_IMAGE_SIZE/image.size.height;
    double scale = pow(2, 1.0/numberPyramids);

    //Pyramid limits
    if(self.finPyramid == 0) self.finPyramid = numberPyramids;
    
    //locate pyramids already calculated in the buffer
    BOOL found;
    NSUInteger index;
    if(self.isLearning){
        found = YES;
        index = [self.receivedImages indexOfObject:image];
        if(index == NSNotFound or self.receivedImages.count == 0){
            [self.receivedImages addObject:image];
            found = NO;
        }
    }
//    dispatch_queue_t myQueue = dispatch_queue_create("com.mycompany.myqueue", 0);
//    dispatch_async(myQueue, ^{
//        printf("this is a block!\n");
//    });
    
    
//    HogFeature *originalImageHog = [[image scaleImageTo:initialScale] obtainHogFeatures];
    //pyramid
    for (int i=self.iniPyramid; i<self.finPyramid; i++){
        HogFeature *imageHog;
        if(!self.isLearning){
            UIImage *im = [image scaleImageTo:initialScale/pow(scale, i)];
//            NSLog(@"image size: %f, %f", im.size.width, im.size.height);
            imageHog = [im obtainHogFeatures];
//            imageHog = [UIImage scaleHog:originalImageHog to:i for:numberPyramids];
//            NSLog(@"original sizes: %d, %d for scale:%d", imageHog.numBlocksY, imageHog.numBlocksX,i);
//            NSLog(@"levels: ini:%d, fin:%d", self.iniPyramid, self.finPyramid);
            [candidateBoundingBoxes addObjectsFromArray:[self getBoundingBoxesIn:imageHog forPyramid:i forIndex:0]];
        }else{
            if (!found) {
                UIImage *im = [image scaleImageTo:initialScale/pow(scale, i)];
                imageHog = [im obtainHogFeatures];
                int indexRR = 0;
                [self.imagesHogPyramid addObject:imageHog];
                indexRR = self.imagesHogPyramid.count - 1;
                [candidateBoundingBoxes addObjectsFromArray:[self getBoundingBoxesIn:imageHog forPyramid:i forIndex:indexRR]];
            }else{
                imageHog = (HogFeature *)[self.imagesHogPyramid objectAtIndex:(index*numberPyramids + i)];
                [candidateBoundingBoxes addObjectsFromArray:[self getBoundingBoxesIn:imageHog forPyramid:i forIndex:(index*numberPyramids + i)]];
            }
        }
    }
    
    
    //sort array of bounding boxes by score
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *candidateBoundingBoxesSorted = [candidateBoundingBoxes sortedArrayUsingDescriptors:sortDescriptors];
    
//    for(BoundingBox *bb in candidateBoundingBoxesSorted)
//        NSLog(@"level: %d, score: %f", bb.pyramidLevel, bb.score);
//    NSLog(@"\n");
    
    NSArray *nmsArray = candidateBoundingBoxesSorted;
    if(useNms) nmsArray = [ConvolutionHelper nms:candidateBoundingBoxesSorted maxOverlapArea:0.25 minScoreThreshold:detectionThreshold]; 

    if(!self.isLearning && nmsArray.count > 0){
        //get the level of the maximum score bb
        int level = [(BoundingBox*)[nmsArray objectAtIndex:0] pyramidLevel];
        self.iniPyramid = level>1 ? level - 1 : 0;
        self.finPyramid = (level<numberPyramids) ? level + 1 :numberPyramids;
        if(level == 0) self.finPyramid=2; else NSLog(@"found at level:%d !!", level);
    }else{
        self.iniPyramid = 0;
        self.finPyramid = numberPyramids;
    }
    
//    self.iniPyramid = 0;
//    self.finPyramid = numberPyramids;
    
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


- (void) testOnSet:(TrainingSet *)set atThresHold:(float)detectionThreshold
{
    
    //TODO: not multiimage
    NSLog(@"Detection threshold: %f", detectionThreshold);
    int tp=0, fp=0, fn=0;// tn=0;
    for(BoundingBox *groundTruthBoundingBox in set.groundTruthBoundingBoxes){
        bool found = NO;
        UIImage *selectedImage = [set.images objectAtIndex:groundTruthBoundingBox.imageIndex];
        NSArray *detectedBoundingBoxes = [self detect:selectedImage minimumThreshold:detectionThreshold pyramids:10 usingNms:YES deviceOrientation:UIImageOrientationUp];
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
}


#pragma mark
#pragma mark - Encoding

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.weights = [aDecoder decodeObjectForKey:@"weights"];
        self.sizes = [aDecoder decodeObjectForKey:@"sizes"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.targetClass = [aDecoder decodeObjectForKey:@"targetClass"];
        self.numberSV = [aDecoder decodeObjectForKey:@"numberSV"];
        self.numberOfPositives = [aDecoder decodeObjectForKey:@"numberOfPositives"];
        self.precisionRecall = [aDecoder decodeObjectForKey:@"precisionRecall"];
        self.timeLearning = [aDecoder decodeObjectForKey:@"timeLearning"];
        self.imagesUsedTraining = [aDecoder decodeObjectForKey:@"imagesUsedTraining"];
        
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
    [aCoder encodeObject:self.targetClass forKey:@"targetClass"];
    [aCoder encodeObject:self.numberSV forKey:@"numberSV"];
    [aCoder encodeObject:self.numberOfPositives forKey:@"numberOfPositives"];
    [aCoder encodeObject:self.precisionRecall forKey:@"precisionRecall"];
    [aCoder encodeObject:self.timeLearning forKey:@"timeLearning"];
    [aCoder encodeObject:self.imagesUsedTraining forKey:@"imagesUsedTraining"];
}


#pragma mark
#pragma mark - Private methods

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
                p.xmin = (double)(x + 1)/((double)blocks[1] + 2);
                p.xmax = (double)(x + 1)/((double)blocks[1] + 2) + ((double)self.sizesP[1]/((double)blocks[1] + 2));
                p.ymin = (double)(y + 1)/((double)blocks[0] + 2);
                p.ymax = (double)(y + 1)/((double)blocks[0] + 2) + ((double)self.sizesP[0]/((double)blocks[0] + 2));
                p.pyramidLevel = pyramidLevel;
                
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
//    double *ramonet = (double *) malloc(self.sizesP[0]*self.sizesP[1]*self.sizesP[2]*sizeof(double));
    int boundingBoxPosition = p.locationOnImageHog.y + p.locationOnImageHog.x*imageHog.numBlocksY;
    for(int f=0; f<self.sizesP[2]; f++)
        for(int i=0; i<self.sizesP[1]; i++)
            for(int j=0; j<self.sizesP[0]; j++){
                int sweeping1 = j + i*self.sizesP[0] + f*self.sizesP[0]*self.sizesP[1];
                int sweeping2 = j + i*imageHog.numBlocksY + f*imageHog.numBlocksX*imageHog.numBlocksY;
                trainingSet.imageFeatures[index*numOfFeatures + sweeping1] = (float) imageHog.features[boundingBoxPosition + sweeping2];
//                ramonet[sweeping1] = imageHog.features[boundingBoxPosition + sweeping2];
            }
//    if(p.label == 1){
//        [self.imageListAux addObject:[UIImage hogImageFromFeature:imageHog]];
//        [self.imageListAux addObject:[UIImage hogImageFromFeatures:ramonet withSize:self.sizesP]];
//        NSLog(@"********ADDED IMAGE**********");
//        NSLog(@"on image: %d, %d with template size: %d, %d", imageHog.numBlocksX, imageHog.numBlocksY, self.sizesP[0], self.sizesP[1]);
//        NSLog(@"(x,y): (%f,%f)", p.locationOnImageHog.x, p.locationOnImageHog.y);
//    }

    
    trainingSet.numberOfTrainingExamples++;
//    free(ramonet);
}



- (void) getBoundingBoxesForTrainingWith:(TrainingSet *) trainingSet
{
    int positives = 0;
    trainingSet.numberOfTrainingExamples = numSupportVectors;
    for(int i=0; i<trainingSet.images.count; i++){
        UIImage *image = [trainingSet.images objectAtIndex:i];
        NSArray *newBoundingBoxes = [self detect:image minimumThreshold:-1 pyramids:10 usingNms:NO deviceOrientation:UIImageOrientationUp];
        [self.delegate sendMessage:[NSString stringWithFormat:@"New bb obtained for image %d: %d", i, newBoundingBoxes.count]];
        int quota = MAX_QUOTA;
        NSArray *selectedGT = trainingSet.groundTruthBoundingBoxes;
        NSMutableArray *aux = [selectedGT mutableCopy];
        
        for(BoundingBox *newBB in newBoundingBoxes){
            BOOL isNegative = NO;
            for(BoundingBox *groundTruthBB in selectedGT){
                if(groundTruthBB.imageIndex == i){
                    double overlapArea = [newBB fractionOfAreaOverlappingWith:groundTruthBB];
                    if (overlapArea > 0.8 && overlapArea<1){
                        newBB.label = 1;
                        isNegative = NO;
                        if(trainingSet.numberOfTrainingExamples+1 < MAX_NUMBER_EXAMPLES){
                            [self addExample:newBB to:trainingSet];
                            positives ++;
                        }else NSLog(@"Training Buffer FULL!!");
                    }else if(overlapArea < 0.25 && quota>0) isNegative = YES;
                }else [aux removeObject:groundTruthBB];
                
            }
            selectedGT = aux;
            if(isNegative){
                newBB.label = -1;
                quota--;
                [self addExample:newBB to:trainingSet];
            }
        }
    }
    
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
