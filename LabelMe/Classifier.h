//
//  Classifier.h
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 28/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#import <Foundation/Foundation.h>


//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TrainingSet
//////////////////////////////////////////////////////////////////////////


@interface TrainingSet : NSObject

@property (strong, nonatomic) NSMutableArray *images; //UIImage
@property (strong, nonatomic) NSMutableArray *groundTruthBoundingBoxes; //ConvolutionPoint
@property (strong, nonatomic) NSMutableArray *boundingBoxes; //ConvolutionPoints
@property CGSize templateSize;

@property float *imageFeatures; //the features for the wole trainingset
@property float *labels; //the corresponding labels
@property int numberOfTrainingExamples; // bounding boxes + support vectors added


//Given a training set of images and ground truth bounding boxes it generates a set of positive and negative bounding boxes for training
- (void) initialFill;

//Generates the hog features given the bounding boxes begining after numSV positions, corresponding to the sv
- (void) generateFeaturesForBoundingBoxesWithNumSV:(int)numSV;

@end



//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Classifier
//////////////////////////////////////////////////////////////////////////

@protocol ClassifierDelegate <NSObject>

//Send a message to the delegate (to output as a debug during the traingnin)
- (void) sendMessage:(NSString *) message;

@end


@interface Classifier : NSObject <NSCoding>

@property double *svmWeights;
@property int *weightsDimensions;
@property (strong, nonatomic) id<ClassifierDelegate> delegate;

//Encoding properties
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *targetClass;
@property (strong, nonatomic) NSMutableArray *weights;
@property (strong, nonatomic) NSArray *sizes;
@property (strong, nonatomic) NSNumber *numberSV;
@property (strong, nonatomic) NSNumber *numberOfPositives;
@property (strong, nonatomic) NSArray *precisionRecall;



//Initialization of the classifier given the weight vectors of it
- (id) initWithTemplateWeights:(double *)templateWeights;

- (id) initWithCoder:(NSCoder *)aDecoder;

//Train the classifier given an initial set formed by Images and ground truth bounding boxes containing positive examples
- (void) train:(TrainingSet *) trainingSet;

//Detect object in the image and return array of convolution points for the indicated number of pyramids and detection threshold
- (NSArray *) detect:(UIImage *) image
    minimumThreshold:(double) detectionThreshold
            pyramids:(int) numberPyramids
            usingNms:(BOOL)useNms
   deviceOrientation:(int) orientation;

//Given a set with ground truth bounding boxes, returns the metric spesified.
- (void) testOnSet:(TrainingSet *)set atThresHold:(float)detectionThreshold;


@end