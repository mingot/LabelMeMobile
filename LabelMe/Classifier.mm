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


#define MAX_IMAGE_SIZE 300.0



@interface Classifier ()

//Show just the histogram features for debugging purposes
- (void) showOrientationHistogram;

//make the convolution of the classifier with the image and return de detected bounding boxes
- (NSArray *) getBoundingBoxesIn:(UIImage *)image;

@end


@implementation Classifier


@synthesize weightsP = _weightsP;
@synthesize sizesP = _sizesP;
@synthesize delegate = _delegate;
@synthesize isLearning = _isLearning;

@synthesize weights = _weights;
@synthesize sizes = _sizes;
@synthesize name = _name;
@synthesize targetClass = _targetClass;
@synthesize numberSV = _numberSV;
@synthesize numberOfPositives = _numberOfPositives;
@synthesize precisionRecall = _precisionRecall;


#pragma mark -
#pragma mark Classifier Public Methods


- (id) initWithTemplateWeights:(double *)templateWeights
{
        
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
    //free previous weights
    free(self.weightsP);
    free(self.sizesP);
    
    self.isLearning = YES;
    
    // Get the template size and get hog feautures dimension
    self.sizesP = [[[trainingSet.images objectAtIndex:0] resizedImage:trainingSet.templateSize interpolationQuality:kCGInterpolationDefault] obtainDimensionsOfHogFeatures];
    int numOfFeatures = self.sizesP[0]*self.sizesP[1]*self.sizesP[2];
    
    if(debugging){
        //NSLog(@"template size: %f, %f", trainingSet.templateSize.height, trainingSet.templateSize.width);
        //NSLog(@"dimensions of hog features: %d %d %d", self.sizesP[0],self.sizesP[1],self.sizesP[2]);
        [self.delegate sendMessage:[NSString stringWithFormat:@"template size: %f, %f", trainingSet.templateSize.height, trainingSet.templateSize.width]];
        [self.delegate sendMessage:[NSString stringWithFormat:@"dimensions of hog features: %d %d %d", self.sizesP[0],self.sizesP[1],self.sizesP[2]]];
    }
    

    //TODO: max size for the buffers
    trainingSet.imageFeatures = (float *) malloc(MAX_NUMBER_EXAMPLES*MAX_NUMBER_FEATURES*sizeof(float));
    trainingSet.labels = (float *) malloc(MAX_NUMBER_EXAMPLES*sizeof(float));
    [trainingSet generateFeaturesForBoundingBoxesWithNumSV:0];
    
    // Set up SVM's parameters
    CvSVMParams params;
    params.svm_type    = CvSVM::C_SVC;
    params.kernel_type = CvSVM::LINEAR;
    params.term_crit   = cvTermCriteria(CV_TERMCRIT_ITER, 1000, 1e-6);
    
    //convergence loop
    int numIterations = 4;
    for (int iter=0; iter<numIterations; iter++){
        // Set up training data
        if(debugging){
            //NSLog(@"\n\n ************************ Iteration %d ********************************", iter);
            //NSLog(@"Number of Training Examples: %d", trainingSet.numberOfTrainingExamples);

            [self.delegate sendMessage:[NSString stringWithFormat:@"\n******* Iteration %d ******", iter]];
            [self.delegate sendMessage:[NSString stringWithFormat:@"Number of Training Examples: %d", trainingSet.numberOfTrainingExamples]];
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
        self.weightsP = (double *) calloc((numOfFeatures+1),sizeof(double)); //TODO: not to be allocated in every iteration
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
            free(sv_aux);
            printf("label: %f   alpha: %f \n", trainingSet.labels[i], alpha);
            
            for(int j=0;j<numOfFeatures;j++){
                // add to get the svm weights
                self.weightsP[j] -= (double) alpha * supportVector[j];
                
                //store the support vector as the first features
                trainingSet.imageFeatures[i*numOfFeatures + j] = supportVector[j];
            }
        }
        self.weightsP[numOfFeatures] = - (double) dec[0].rho; // The sign of the bias and rho have opposed signs.
        
        if(debugging){
            //NSLog(@"bias: %f", self.weightsP[numOfFeatures]);
            [self.delegate sendMessage:[NSString stringWithFormat:@"bias: %f", self.weightsP[numOfFeatures]]];
        }
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        //Update bounding boxes
        //////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        //remove all current bounding boxes
        [trainingSet.boundingBoxes removeAllObjects];
        trainingSet.numberOfTrainingExamples = numSupportVectors;
        int positives = 0, index = numSupportVectors;
        
        for(BoundingBox *groundTruthBoundingBox in trainingSet.groundTruthBoundingBoxes){
        
            // Get new bounding boxes by running the detector
            UIImage *image = [trainingSet.images objectAtIndex:groundTruthBoundingBox.imageIndex];
            HogFeature *imageHog = [image obtainHogFeatures];
            NSArray *newBoundingBoxes = [self detect:image minimumThreshold:-1 pyramids:10 usingNms:NO deviceOrientation:UIImageOrientationUp];
            
            NSLog(@"Number of new bb obtained for image %d: %d", groundTruthBoundingBox.imageIndex, newBoundingBoxes.count);
            //the rest that are less than an overlap threshold are considered negatives
            for(BoundingBox *boundingBox in newBoundingBoxes){
                double overlapArea = [boundingBox fractionOfAreaOverlappingWith:groundTruthBoundingBox];
                BOOL addBB = NO;
                if (overlapArea < 0.25){
                    boundingBox.label = -1;
                    addBB = YES;
                }else if (overlapArea > 0.8 && overlapArea<1){
                    boundingBox.label = 1;
                    addBB = YES;
                    positives ++;
                }
                
                // add the convolution point to the training buffer
                if (addBB) {
                    [self addExample:boundingBox to:trainingSet startingAt:index for:imageHog];
                    index++;
                    trainingSet.numberOfTrainingExamples++;
                }
            }
        }
        if(debugging){
            [self.delegate sendMessage:[NSString stringWithFormat:@"added:%d positives", positives]];
            [self.delegate sendMessage:@"Computing HOG features for the Bounding boxes..."];
        }
        
        
        //generate the hog features for the new bounding boxes
//        [trainingSet generateFeaturesForBoundingBoxesWithNumSV:numSupportVectors];
        
        
        //update information about the classifier
        self.numberOfPositives = [NSNumber numberWithInt:positives];
        self.numberSV = [NSNumber numberWithInt:numSupportVectors];
    }
    
    //See the results on training set
    [self testOnSet:trainingSet atThresHold:0];
    self.isLearning = NO;
}




- (NSArray *) detect:(UIImage *)image
    minimumThreshold:(double) detectionThreshold
            pyramids:(int)numberPyramids
            usingNms:(BOOL)useNms
   deviceOrientation:(int)orientation
{
    
    NSMutableArray *candidateBoundingBoxes = [[NSMutableArray alloc] init];
    
    //rotate image depending on the orientation
    if(UIDeviceOrientationIsLandscape(orientation))
        image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation: UIImageOrientationUp];

    double initialScale = MAX_IMAGE_SIZE/image.size.height;
    double scale = pow(3, 1.0/numberPyramids);

    //Pyramid calculation
    for (int i = 0; i<numberPyramids; i++){
        UIImage *im = [image scaleImageTo:initialScale/pow(scale, i)];
        NSArray *result = [self getBoundingBoxesIn:im];
        
//        NSLog(@"image size: h:%f, w:%f", im.size.height, im.size.width);
        [candidateBoundingBoxes addObjectsFromArray:result];
    }
    
    NSArray *nmsArray = candidateBoundingBoxes;
    if(useNms) nmsArray = [ConvolutionHelper nms:candidateBoundingBoxes maxOverlapArea:0.25 minScoreThreshold:detectionThreshold]; 
    
    // Change the resulting orientation of the bounding boxes if the phone orientation requires it
    if(UIInterfaceOrientationIsLandscape(orientation)){
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


- (NSArray *) getBoundingBoxesIn:(UIImage *)image
{
    HogFeature *imageHog = [image obtainHogFeatures];
    int blocks[2] = {imageHog.numBlocksY, imageHog.numBlocksX};
    
    int convolutionSize[2];
    convolutionSize[0] = blocks[0] - self.sizesP[0] + 1; //convolution size
    convolutionSize[1] = blocks[1] - self.sizesP[1] + 1;
    if ((convolutionSize[0]<=0) || (convolutionSize[1]<=0))
        return NULL;
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:convolutionSize[0]*convolutionSize[1]];
    double *c = (double *) calloc(convolutionSize[0]*convolutionSize[1],sizeof(double)); //initialize the convolution result
    
    
    // Make the convolution for each feature.
    for (int f = 0; f < self.sizesP[2]; f++){
        
        double *dst = c;
        double *A_src = imageHog.features + f*blocks[0]*blocks[1]; //Select the block of features to do the convolution with
        double *B_src = self.weightsP + f*self.sizesP[0]*self.sizesP[1];
        
        // convolute and add the results to dst
        [ConvolutionHelper convolution:dst matrixA:A_src :blocks matrixB:B_src :self.sizesP];
        //[ConvolutionHelper convolutionWithVDSP:dst matrixA:A_src :blocks matrixB:B_src :templateSize];
        
    }
    
    //Once done the convolution, detect if something is the object!
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
                p.locationOnImageHog = CGPointMake(x, y);
                
                [result addObject:p];
            }
        }
    }
    
    free(c);
    return result;
}

-(void) addExample:(BoundingBox *)p to:(TrainingSet *)trainingSet startingAt:(int)index for:(HogFeature *)imageHog
{
    //label
    trainingSet.labels[index] = p.label;
    
    //features
    int boundingBoxPosition = p.locationOnImageHog.y + p.locationOnImageHog.x*self.sizesP[0];
    int numOfFeatures = self.sizesP[0]*self.sizesP[1]*self.sizesP[2];
    for(int f=0; f<self.sizesP[2];f++)
        for(int i=0;i<self.sizesP[1];i++)
            for(int j=0;j<self.sizesP[0];j++){
                int sweeping = j + i*self.sizesP[0] + f*self.sizesP[0]*self.sizesP[1];
                trainingSet.imageFeatures[index*numOfFeatures + sweeping] = (float) imageHog.features[boundingBoxPosition + sweeping];
            }
}


@end
