//
//  ConvolutionHelper.h
//  TestDetector
//
//  Created by Josep Marc Mingot Hidalgo on 07/02/13.
//  Copyright (c) 2013 Dolores. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetectView.h"
#import "Classifier.h"



@interface BoundingBox : NSObject


@property double score;
@property double xmin;
@property double xmax;
@property double ymin;
@property double ymax;

@property int label;
@property int imageIndex;
@property int pyramidLevel;
@property CGRect rectangle;

@property CGPoint locationOnImageHog;
//index in for the classifier array of hog features of the pyramids
@property int imageHogIndex;

-(id) initWithRect:(CGRect)initialRect label:(int)label imageIndex:(int)imageIndex;
- (CGRect) rectangleForImage:(UIImage *)image;
- (double) fractionOfAreaOverlappingWith:(BoundingBox *) cp;

@end




@interface ConvolutionHelper : NSObject

+ (void) convolution:(double *)result matrixA:(double *)matrixA :(int *)sizeA matrixB:(double *)matrixB :(int *)sizeB;

+ (NSArray *)nms:(NSArray *)boundingBoxesCandidates maxOverlapArea:(double)overlap minScoreThreshold:(double)scoreThreshold;

@end



