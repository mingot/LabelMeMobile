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


@property (strong, nonatomic) id<ClassifierDelegate> delegate;


@property int *sizesP;
@property double *weightsP;
@property NSMutableArray *imageListAux;

//Encoding properties
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *targetClass;
@property (strong, nonatomic) NSMutableArray *weights;
@property (strong, nonatomic) NSArray *sizes;
@property (strong, nonatomic) NSNumber *numberSV;
@property (strong, nonatomic) NSNumber *numberOfPositives;
@property (strong, nonatomic) NSArray *precisionRecall;
@property (strong, nonatomic) NSNumber *timeLearning;
@property (strong, nonatomic) NSMutableArray *imagesUsedTraining;



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
   deviceOrientation:(int) orientation
  learningImageIndex:(int) imageIndex;

//Given a set with ground truth bounding boxes, returns the metric spesified.
- (void) testOnSet:(TrainingSet *)set atThresHold:(float)detectionThreshold;


@end