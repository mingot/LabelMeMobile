//
//  Classifier.h
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 28/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrainingSet.h"



@protocol ClassifierDelegate <NSObject>

//Send a message to the delegate (to output as a debug during the traingnin)
- (void) sendMessage:(NSString *) message;
- (void) updateProgress:(float) prog;

@end


@interface Classifier : NSObject <NSCoding>

//pointer version of size and weights
@property double *weightsP;
@property int *sizesP;
@property (strong, nonatomic) id<ClassifierDelegate> delegate;
@property BOOL isLearning;
@property NSMutableArray *imageListAux;

//pyramid limits for detection in execution
@property int iniPyramid;
@property int finPyramid;

//Encoding properties
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *targetClass;
@property (strong, nonatomic) NSMutableArray *weights;
@property (strong, nonatomic) NSArray *sizes;
@property (strong, nonatomic) NSNumber *numberSV;
@property (strong, nonatomic) NSNumber *numberOfPositives;
@property (strong, nonatomic) NSArray *precisionRecall;

//detector buffer (when training)
@property (strong, nonatomic) NSMutableArray *receivedImages;
@property (strong, nonatomic) NSMutableArray *imagesHogPyramid;


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