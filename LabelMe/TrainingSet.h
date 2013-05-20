//
//  TrainingSet.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TrainingSet : NSObject

@property (strong, nonatomic) NSMutableArray *images; //UIImage
@property (strong, nonatomic) NSMutableArray *groundTruthBoundingBoxes; //BoundingBox
@property (strong, nonatomic) NSMutableArray *boundingBoxes; //BoundingBox

@property CGSize templateSize;
//ratio between the average area of the bounding boxes inside the images
@property float areaRatio;

@property float *imageFeatures; //the features for the wole trainingset
@property float *labels; //the corresponding labels
@property int numberOfTrainingExamples; // bounding boxes + support vectors added


//modify the actual ground truth bounding boxes to handle a special confilictive case in learning. That case was when images with rectangular ground truth bb combined horizontal anv vertical rectangles. This methods transforms all those rectangles in the circumscrite square containing them
- (void) unifyGroundTruthBoundingBoxes;

@end
