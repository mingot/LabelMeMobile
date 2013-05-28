//
//  Pyramid.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 20/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+HOG.h"

@interface Pyramid : NSObject

//indexes of the pyramids to calculate according to each detector. If a detector detects the object in a specified pyramid level, on the next iteration it will only be computing some levels up and down. Avoid having to calculate all the levels if not necessary.
@property (nonatomic, strong) NSMutableSet *levelsToCalculate;

//hog feature for each level
@property (atomic, strong) NSMutableArray *hogFeatures;

@property int numPyramids;


- (id) initWithClassifiers:(NSArray *) svmClassifiers forNumPyramids:(int) numPyramids;


//
- (void) constructPyramidForImage:(UIImage *)image withOrientation:(int)orientation;


@end
