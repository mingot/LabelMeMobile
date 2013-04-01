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

#define debugging YES
#define MAX_NUMBER_EXAMPLES 20000
#define MAX_NUMBER_FEATURES 2000

////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TrainingSet
////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TrainingSet

@synthesize images = _images;
@synthesize groundTruthBoundingBoxes = _groundTruthBoundingBoxes;
@synthesize boundingBoxes = _boundingBoxes;
@synthesize imageFeatures = _imageFeatures;
@synthesize labels = _labels;
@synthesize templateSize = _templateSize;

- (void) setTemplateSize:(CGSize)templateSize
{
    _templateSize = templateSize;
}


#define SCALE_FACTOR 0.08 //resize template to obtain a reasonable number of blocks for the hog features

- (CGSize) templateSize
{
    //compute template size in case it is not set (lazy instantiation)
    if(_templateSize.height == 0.0){
        NSLog(@"Computing template size...");
        CGSize averageSize;
        averageSize.height = 0;
        averageSize.width = 0;
        
        for(ConvolutionPoint* groundTruthBB in self.groundTruthBoundingBoxes){
            averageSize.height += groundTruthBB.ymax - groundTruthBB.ymin;
            averageSize.width += groundTruthBB.xmax - groundTruthBB.xmin;
        }
        
        //compute the average and get the average size in the image dimensions
        CGSize imgSize = [[self.images objectAtIndex:0] size];
        averageSize.height = averageSize.height*imgSize.height*SCALE_FACTOR/self.groundTruthBoundingBoxes.count;
        averageSize.width = averageSize.width*imgSize.width*SCALE_FACTOR/self.groundTruthBoundingBoxes.count;
        
        HogFeature *hog = [[[self.images objectAtIndex:0] resizedImage:averageSize interpolationQuality:kCGInterpolationDefault] obtainHogFeatures];
        
        _templateSize = averageSize;
        
        NSLog(@"Template size setted: h:%f, w:%f", _templateSize.height, _templateSize.width);
        NSLog(@"Hog features size: %d, %d, %d", hog.numBlocksX, hog.numBlocksY, hog.numFeaturesPerBlock);
    }
    return _templateSize;
}


-(id) init
{
    self = [super init];
    if (self) {
        self.images = [[NSMutableArray alloc] init];
        self.groundTruthBoundingBoxes = [[NSMutableArray alloc] init];
        self.boundingBoxes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) initialFill
{
    // Create a initial set of positive and negative bounding boxes from ground truth labeled images
    self.boundingBoxes = [[NSMutableArray alloc] initWithArray:self.groundTruthBoundingBoxes];
    
    for(int i=0; i<self.groundTruthBoundingBoxes.count; i++){
        
        //Ground truth for the image
        //TODO: suposing one ground truth per image
        ConvolutionPoint *groundTruth = [self.groundTruthBoundingBoxes objectAtIndex:i];
        UIImage *image = [self.images objectAtIndex:groundTruth.imageIndex];
        
        //the new box will have the size of the template size (not necessary though)
        float height = self.templateSize.height/image.size.height;
        float width = self.templateSize.width/image.size.width;
        
        double randomX;
        double randomY;
        
        int num=20;
        for(int j=0; j<num/2;j++){
            
            if(j%4==0){
                randomX = 0;
                randomY = j*1.0/num;
            }else if(j%4==1){
                randomX = j*1.0/num;
                randomY = 0;
            }else if(j%4==2){
                randomX = 1 - width;
                randomY = j*1.0/num;
            }else{
                randomX = j*1.0/num;
                randomY = 1-height;
            }
            
            ConvolutionPoint *negativeExample = [[ConvolutionPoint alloc] initWithRect:CGRectMake(randomX, randomY, width, height) label:-1 imageIndex:groundTruth.imageIndex];
            
            if([negativeExample fractionOfAreaOverlappingWith:groundTruth]<0.1)
                [self.boundingBoxes addObject:negativeExample];
        }
        
        
        self.numberOfTrainingExamples = self.boundingBoxes.count;
    }
}



- (void) generateFeaturesForBoundingBoxesWithTemplateSize:(CGSize)templateSize withNumSV:(int)numSV
{
    // transform each bounding box into hog feature space
    int i;
    for(i=0; i<self.boundingBoxes.count; i++)
    {
        @autoreleasepool
        {
            ConvolutionPoint *boundingBox = [self.boundingBoxes objectAtIndex:i];
            
            //get the image contained in the bounding box and resized it with the template size
            //TODO: From cut -> HOG to HOG -> cut
            UIImage *wholeImage = [self.images objectAtIndex:boundingBox.imageIndex];
            UIImage *resizedImage = [[wholeImage croppedImage:[boundingBox rectangleForImage:wholeImage]] resizedImage:self.templateSize interpolationQuality:kCGInterpolationDefault];
            
            //calculate the hogfeatures of the image
            HogFeature *hogFeature = [resizedImage obtainHogFeatures];
            
            //check if it has enough space to allocate it
            if((i+1+numSV)*hogFeature.totalNumberOfFeatures > MAX_NUMBER_EXAMPLES*MAX_NUMBER_FEATURES*sizeof(float))
            {
                NSLog(@"BUFFER FULL!!");
                break;
            }
            
            //add the label
            self.labels[numSV + i] = (float) boundingBox.label;
            
            //add the hog features
            for(int j=0; j<hogFeature.totalNumberOfFeatures; j++)
                self.imageFeatures[(numSV + i)*hogFeature.totalNumberOfFeatures + j] = (float) hogFeature.features[j];
        }

    }
    self.numberOfTrainingExamples = numSV + i;
}

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Classifier
////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface Classifier ()

//Show just the histogram features for debugging purposes
- (void) showOrientationHistogram;

@end



@implementation Classifier


@synthesize svmWeights = _svmWeights;
@synthesize weightsDimensions = _weightsDimensions;

@synthesize weights = _weights;
@synthesize sizes = _sizes;
@synthesize name = _name;
@synthesize targetClass = _targetClass;


#pragma mark -
#pragma mark Classifier Public Methods


- (id) initWithTemplateWeights:(double *)templateWeights
{
        
    if(self = [super init])
    {
        self.weightsDimensions = (int *) malloc(3*sizeof(int));
        self.weightsDimensions[0] = (int) templateWeights[0];
        self.weightsDimensions[1] = (int) templateWeights[1];
        self.weightsDimensions[2] = (int) templateWeights[2];
        
        int numberOfSvmWeights = self.weightsDimensions[0]*self.weightsDimensions[1]*self.weightsDimensions[2] + 1; //+1 for the bias 
        self.svmWeights = (double *) malloc(numberOfSvmWeights*sizeof(double));
        for(int i=0; i<numberOfSvmWeights; i++) 
            self.svmWeights[i] = templateWeights[3 + i];
    }
    
    return self;
}

- (id) init
{
    if (self = [super init]) {
        self.weightsDimensions = (int *) malloc(3*sizeof(int));
        self.weightsDimensions[0] = 1;
        self.weightsDimensions[1] = 1;
        self.weightsDimensions[2] = 1;
        
        self.svmWeights = (double *) malloc(sizeof(double));
        self.svmWeights[0] = 0;
    }
    
    return self;
}



- (void) printListHogFeatures:(float *) listOfHogFeaturesFloat
{
    //Print unoriented hog features for debugging purposes
    for(int y=0; y<self.weightsDimensions[0]; y++){
        for(int x=0; x<self.weightsDimensions[1]; x++){
            for(int f = 18; f<27; f++){
                printf("%f ", listOfHogFeaturesFloat[y + x*7 + f*7*5]);
//                if(f==17 || f==26) printf("  |  ");
            }
            printf("\n");
        }
        printf("\n*************************************************************************\n");
    }
}

- (void) showOrientationHistogram
{
    double *histogram = (double *) calloc(18,sizeof(double));
    for(int x = 0; x<self.weightsDimensions[1]; x++)
        for(int y=0; y<self.weightsDimensions[0]; y++)
            for(int f=18; f<27; f++)
                histogram[f-18] += self.svmWeights[y + x*self.weightsDimensions[0] + f*self.weightsDimensions[0]*self.weightsDimensions[1]];
    
    printf("Orientation Histogram\n");
    for(int i=0; i<9; i++)
        printf("%f ", histogram[i]);
    printf("\n");
    
    free(histogram);
}

- (void) train:(TrainingSet *) trainingSet;
{
    //free previous weights
    free(self.svmWeights);
    free(self.weightsDimensions);
    
    // Get the template size and get hog feautures dimension
    [trainingSet initialFill];
    self.weightsDimensions = [[[trainingSet.images objectAtIndex:0] resizedImage:trainingSet.templateSize interpolationQuality:kCGInterpolationDefault] obtainDimensionsOfHogFeatures];
    int numOfFeatures = self.weightsDimensions[0]*self.weightsDimensions[1]*self.weightsDimensions[2];
    
    if(debugging){
        NSLog(@"template size: %f, %f", trainingSet.templateSize.height, trainingSet.templateSize.width);
        NSLog(@"dimensions of hog features: %d %d %d", self.weightsDimensions[0],self.weightsDimensions[1],self.weightsDimensions[2]);
    }
    

    //TODO: max size for the buffers
    trainingSet.imageFeatures = (float *) malloc(MAX_NUMBER_EXAMPLES*MAX_NUMBER_FEATURES*sizeof(float));
    trainingSet.labels = (float *) malloc(MAX_NUMBER_EXAMPLES*sizeof(float));
    [trainingSet generateFeaturesForBoundingBoxesWithTemplateSize:trainingSet.templateSize withNumSV:0];
    
    // Set up SVM's parameters
    CvSVMParams params;
    params.svm_type    = CvSVM::C_SVC;
    params.kernel_type = CvSVM::LINEAR;
    params.term_crit   = cvTermCriteria(CV_TERMCRIT_ITER, 1000, 1e-6);
    
    //convergence loop
    int numIterations = 1;
    for (int i=0; i<numIterations; i++){
        // Set up training data
        if(debugging){
            NSLog(@"\n\n ************************ Iteration %d ********************************", i);
            NSLog(@"Number of Training Examples: %d", trainingSet.numberOfTrainingExamples);
            
        }
        
        
        Mat labelsMat(trainingSet.numberOfTrainingExamples,1,CV_32FC1, trainingSet.labels);
        Mat trainingDataMat(trainingSet.numberOfTrainingExamples, numOfFeatures, CV_32FC1, trainingSet.imageFeatures);
        //std::cout << trainingDataMat << std::endl; //output learning matrix
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        //Train the SVM, update weights and store support vectors and labels
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
    
        CvSVM SVM;
        SVM.train(trainingDataMat, labelsMat, Mat(), Mat(), params);
        
        //update weights and store the support vectors
        int numSupportVectors = SVM.get_support_vector_count();
        const CvSVMDecisionFunc *dec = SVM.decision_func;
        self.svmWeights = (double *) calloc((numOfFeatures+1),sizeof(double)); //TODO: not to be allocated in every iteration
        printf("Num of support vectors: %d\n", numSupportVectors);
        
        for (int i = 0; i<numSupportVectors; ++i){
            float alpha = dec[0].alpha[i];
            const float *supportVector = SVM.get_support_vector(i);
            float *sv_aux = (float *) malloc(numOfFeatures*sizeof(float));
            for(int j=0;j<numOfFeatures;j++) //const float* to float*
                sv_aux[j] = supportVector[j];
            
            // Get the current label of the supportvector
            Mat supportVectorMat(numOfFeatures,1,CV_32FC1, sv_aux);
            trainingSet.labels[i] = SVM.predict(supportVectorMat);
            printf("label: %f   alpha: %f \n", trainingSet.labels[i], alpha);
            
            for(int j=0;j<numOfFeatures;j++){
                // add to get the svm weights
                self.svmWeights[j] -= (double) alpha * supportVector[j];
                
                //store the support vector as the first features
                trainingSet.imageFeatures[i*numOfFeatures +j] = supportVector[j];
            }
        }
        self.svmWeights[numOfFeatures] = - (double) dec[0].rho; // The sign of the bias and rho have opposed signs.
        
        if(debugging){
            NSLog(@"bias: %f", self.svmWeights[numOfFeatures]);
        }
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        //Update bounding boxes
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        //remove all current bounding boxes
        [trainingSet.boundingBoxes removeAllObjects];
        int positives = 0;
        
        for(int imageIndex=0; imageIndex<trainingSet.images.count; imageIndex++){
            // Get new bounding boxes by running the detector
            NSArray *newBoundingBoxes = [self detect:[trainingSet.images objectAtIndex:imageIndex] minimumThreshold:-1 pyramids:10 usingNms:NO deviceOrientation:UIImageOrientationUp];
            if(debugging) NSLog(@"Number of new bb obtained: %d", [newBoundingBoxes count]);
            
            //the rest that are less than an overlap threshold are considered negatives
            ConvolutionPoint *groundTruthBoundingBox = [trainingSet.groundTruthBoundingBoxes objectAtIndex:0];
            for(int j=0; j<[newBoundingBoxes count]; j++){
                ConvolutionPoint *boundingBox = [newBoundingBoxes objectAtIndex:j];
                boundingBox.imageIndex = imageIndex;
                double overlapArea = [boundingBox fractionOfAreaOverlappingWith:groundTruthBoundingBox];
                
                if (overlapArea < 0.25){
                    boundingBox.label = -1;
                    [trainingSet.boundingBoxes addObject:boundingBox];
                    
                }else if (overlapArea > 0.8 && overlapArea<1){
                    boundingBox.label = 1;
                    positives ++;
                    [trainingSet.boundingBoxes addObject:boundingBox];
                }
                
            }
        }
        printf("added:%d positives\n", positives);
        printf("total of new bounding boxes: %d\n", trainingSet.boundingBoxes.count);
        
        //generate the hog features for the new bounding boxes
//        [trainingSet generateFeaturesForBoundingBoxesWithTemplateSize:trainingSet.templateSize withNumSV:numSupportVectors];
        
        //[self showOrientationHistogram];
        
    }
    
    //See the results on training set
    [self testOnSet:trainingSet atThresHold:0];
}

#define MAX_IMAGE_SIZE 300.0


- (NSArray *) detect:(UIImage *)image
    minimumThreshold:(double) detectionThreshold
            pyramids:(int)numberPyramids
            usingNms:(BOOL)useNms
   deviceOrientation:(int)orientation
{
    
    NSMutableArray *candidateBoundingBoxes = [[NSMutableArray alloc] init];
    
    //rotate image depending on the orientation
    if(UIDeviceOrientationIsLandscape(orientation)){
        image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation: UIImageOrientationUp];
    }

    double initialScale = MAX_IMAGE_SIZE/image.size.height;
    double scale = pow(3, 1.0/numberPyramids);

    //Pyramid calculation
    for (int i = 0; i<numberPyramids; i++){
        UIImage *im = [image scaleImageTo:initialScale/pow(scale, i)];
        NSArray *result = [ConvolutionHelper convolve: im
                                       withClassifier:self];
//        NSLog(@"image size: h:%f, w:%f", im.size.height, im.size.width);
        [candidateBoundingBoxes addObjectsFromArray:result];
    }
    
    NSArray *nmsArray = candidateBoundingBoxes;
    if(useNms) nmsArray = [ConvolutionHelper nms:candidateBoundingBoxes maxOverlapArea:0.25 minScoreThreshold:detectionThreshold]; 
    
    // Change the resulting orientation of the bounding boxes if the phone orientation requires it
    if(UIInterfaceOrientationIsLandscape(orientation)){
        for(int i=0; i<nmsArray.count; i++){
            ConvolutionPoint *boundingBox = [nmsArray objectAtIndex:i];
            double auxXmin, auxXmax;
            auxXmin = boundingBox.xmin;
            auxXmax = boundingBox.xmax;
            boundingBox.xmin = (1 - boundingBox.ymin);//*320.0/504;
            boundingBox.xmax = (1 - boundingBox.ymax);//*320.0/504;
            boundingBox.ymin = auxXmin;//*504.0/320;
            boundingBox.ymax = auxXmax;//*504.0/320;
        }
    }
    
    return nmsArray;
}


- (void) testOnSet:(TrainingSet *)set atThresHold:(float)detectionThreshold
{
    
    NSLog(@"Detection threshold: %f", detectionThreshold);
    int tp=0, fp=0, fn=0;// tn=0;
    for(ConvolutionPoint *groundTruthBoundingBox in set.groundTruthBoundingBoxes){
        bool found = NO;
        UIImage *selectedImage = [set.images objectAtIndex:groundTruthBoundingBox.imageIndex];
        NSArray *detectedBoundingBoxes = [self detect:selectedImage minimumThreshold:detectionThreshold pyramids:10 usingNms:YES deviceOrientation:UIImageOrientationUp];
        NSLog(@"For image %d generated %d detecting boxes", groundTruthBoundingBox.imageIndex, detectedBoundingBoxes.count);
        for(ConvolutionPoint *detectedBoundingBox in detectedBoundingBoxes)
            if ([detectedBoundingBox fractionOfAreaOverlappingWith:groundTruthBoundingBox]>0.5){
                tp++;
                found = YES;
            }else fp++;
        
        if(!found) fn++;
        NSLog(@"tp at image %d: %d", groundTruthBoundingBox.imageIndex, tp);
        NSLog(@"fp at image %d: %d", groundTruthBoundingBox.imageIndex, fp);
        NSLog(@"fn at image %d: %d", groundTruthBoundingBox.imageIndex, fn);
        
    }
    NSLog(@"PRECISION: %f", tp*1.0/(tp+fp));
    NSLog(@"RECALL: %f", tp*1.0/(tp+fn));
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
        
        self.weightsDimensions = (int *) malloc(3*sizeof(int));
        self.weightsDimensions[0] = [(NSNumber *) [self.sizes objectAtIndex:0] intValue];
        self.weightsDimensions[1] = [(NSNumber *) [self.sizes objectAtIndex:1] intValue];
        self.weightsDimensions[2] = [(NSNumber *) [self.sizes objectAtIndex:2] intValue];
        
        NSLog(@"read self.sizes: %@", self.sizes);
        
        int numberOfSvmWeights = self.weightsDimensions[0]*self.weightsDimensions[1]*self.weightsDimensions[2] + 1; //+1 for the bias
        
        self.svmWeights = (double *) malloc(numberOfSvmWeights*sizeof(double));
        for(int i=0; i<numberOfSvmWeights; i++)
            self.svmWeights[i] = [(NSNumber *) [self.weights objectAtIndex:i] doubleValue];
        
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    self.sizes = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithInt:self.weightsDimensions[0]],
                    [NSNumber numberWithInt:self.weightsDimensions[1]],
                    [NSNumber numberWithInt:self.weightsDimensions[2]], nil];
    
    NSLog(@"write self.sizes: %@", self.sizes);
    
    int numberOfSvmWeights = self.weightsDimensions[0]*self.weightsDimensions[1]*self.weightsDimensions[2] + 1; //+1 for the bias
    
    self.weights = [[NSMutableArray alloc] initWithCapacity:numberOfSvmWeights];
    for(int i=0; i<numberOfSvmWeights; i++)
        [self.weights addObject:[NSNumber numberWithDouble:self.svmWeights[i]]];
    
    
    [aCoder encodeObject:self.weights forKey:@"weights"];
    [aCoder encodeObject:self.sizes forKey:@"sizes"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.targetClass forKey:@"targetClass"];
}



@end
