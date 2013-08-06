//
//  DetectorResourceFileHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "TagImageView.h"
#import "Classifier.h"

@interface DetectorResourceHandler : NSObject


- (id) initForUsername:(NSString *)username;
- (NSArray *) getAvailanleObjectClasses;
- (NSArray *) getImagesList;
- (NSMutableArray *) loadDetectors;


- (void) saveDetectors:(NSArray *) detectors;
- (void) removeImageForDetector:(Classifier *) detector;

@end
