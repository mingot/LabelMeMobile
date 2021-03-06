//
//  DetectorResourceFileHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "TagImageView.h"
#import "Detector.h"

@class Detector;

@interface DetectorResourceHandler : NSObject


- (id) initForUsername:(NSString *)username;

- (NSArray *) getObjectClassesNames;
- (NSArray *) getTrainingImages;
- (NSArray *) getImageNamesContainingClasses:(NSArray *)targetClasses;
- (UIImage *) getThumbnailImageWithImageName:(NSString *) imageName;
- (UIImage *) getImageWithImageName:(NSString *) imageName;
- (NSMutableArray *) getBoxesForImageName:(NSString *) imageName;
- (int) getHogFromPreferences;


- (NSMutableArray *) loadDetectors;

- (void) saveDetectors:(NSArray *) detectors;
- (void) saveDetector:(Detector *)detector withImage:(UIImage *)image;
- (void) removeImageForDetector:(Detector *) detector;



@end
