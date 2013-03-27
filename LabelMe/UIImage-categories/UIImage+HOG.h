//
//  UIImage+HOG.h
//  DetectMe
//
//  Created by Josep Marc Mingot Hidalgo on 26/02/13.
//  Copyright (c) 2013 Josep Marc Mingot Hidalgo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HogFeature : NSObject

@property int numBlocksX;
@property int numBlocksY;
@property int numFeaturesPerBlock;
@property int totalNumberOfFeatures;
@property double *features;
@property int *dimensionOfHogFeatures;

- (void) printFeaturesOnScreen;

@end


@interface UIImage (HOG)

- (HogFeature *) obtainHogFeatures;
- (int *) obtainDimensionsOfHogFeatures;
- (UIImage *) convertToHogImage;

+ (UIImage *) hogImageFromFeatures:(double *)hogFeatures withSize:(int *)blocks;


@end
