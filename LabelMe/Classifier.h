//
//  Classifier.h
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 28/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrainingSet.h"
#import "Pyramid.h"



@protocol ClassifierDelegate <NSObject>

//Send a message to the delegate (to output as a debug during the traingnin)
- (void) sendMessage:(NSString *) message;
- (void) updateProgress:(float) prog;

@end


@interface Classifier : NSObject <NSCoding>


@property (strong, nonatomic) id<ClassifierDelegate> delegate;

@property int *sizesP;
@property double *weightsP;
@property NSMutableArray *imageListAux;
@property int maxHog; //hog readed from user preferences;

//Encoding properties
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *targetClasses;
@property (strong, nonatomic) NSString *classifierID;
@property (strong, nonatomic) NSMutableArray *weights;
@property (strong, nonatomic) NSArray *sizes;
@property (strong, nonatomic) NSNumber *numberSV;
@property (strong, nonatomic) NSNumber *numberOfPositives;
@property (strong, nonatomic) NSArray *precisionRecall;
@property (strong, nonatomic) NSNumber *timeLearning;
@property (strong, nonatomic) NSMutableArray *imagesUsedTraining;
@property (strong, nonatomic) NSString *averageImagePath;
@property (strong, nonatomic) NSString *averageImageThumbPath;
@property (strong, nonatomic) NSDate *updateDate;
@property (strong, nonatomic) NSNumber *scaleFactor; //average ratio height/width of the positive bb of the training set
@property (strong, nonatomic) NSNumber *detectionThreshold;


@property BOOL trainCancelled;

//Initialization of the classifier given the weight vectors of it
- (id) initWithTemplateWeights:(double *)templateWeights;


- (id) initWithCoder:(NSCoder *)aDecoder;

//Train the classifier given an initial set formed by Images and ground truth bounding boxes containing positive examples. Returns 1 == success, 0 == fail
- (int) train:(TrainingSet *)trainingSet;

//Detect object in the image and return array of convolution points for the indicated number of pyramids and detection threshold
- (NSArray *) detect:(UIImage *) image
    minimumThreshold:(double) detectionThreshold
            pyramids:(int) numberPyramids
            usingNms:(BOOL)useNms
   deviceOrientation:(int) orientation
  learningImageIndex:(int) imageIndex;

//for multiple detection using a shared pyramid
- (NSArray *) detect:(Pyramid *) hogFeaturePyramid
    minimumThreshold:(double) detectionThreshold
            usingNms:(BOOL)useNms
         orientation:(int)orientation;

//Given a set with ground truth bounding boxes, returns the metric spesified.
- (void) testOnSet:(TrainingSet *)set atThresHold:(float)detectionThreshold;


@end