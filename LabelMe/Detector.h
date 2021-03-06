//
//  Detector.h
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 28/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrainingSet.h"
#import "Pyramid.h"

@class TrainingSet;

@protocol DetectorDelegate <NSObject>

//Send a message to the delegate (to output as a debug during the traingnin)
- (void) sendMessage:(NSString *) message;
- (void) updateProgress:(float) prog;

@end


@interface Detector : NSObject <NSCoding>


@property (strong, nonatomic) id<DetectorDelegate> delegate;

//Encoding properties
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *targetClasses;
@property (strong, nonatomic) NSString *detectorID;
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

// In case of error training, provide specific detail of what has happened
@property (strong, nonatomic, readonly) NSString *errorMessage;


- (id) initWithCoder:(NSCoder *)aDecoder;

// Train the detector given an initial set formed by Images and ground truth bounding boxes containing positive examples.
// Uses MaxHOG as an initial value for HoG dimensions. Common value is 8.
// Returns 0:fail, 1:success, 2:interrupted
- (int) trainOnSet:(TrainingSet *)trainingSet forMaxHOG:(int)maxHog;

//Given a set with ground truth bounding boxes, returns the metric spesified.
- (void) testOnSet:(TrainingSet *)set atThresHold:(float)detectionThreshold;


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


- (void) cancelTraining;

// get the hog image of the weights obtained
- (UIImage *) getHogImageOfTheWeights;

@end