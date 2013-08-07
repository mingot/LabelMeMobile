//
//  SendingView+DetectorDescription.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 07/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "SendingView.h"
#import "Detector.h"

@interface SendingView (DetectorDescription)

- (void) initializeForTraining;

- (void) stopAfterTraining;

- (void) initializeForInfoOfDetector:(Detector *) detector;

@end
