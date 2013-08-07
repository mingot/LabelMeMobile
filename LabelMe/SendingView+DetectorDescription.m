//
//  SendingView+DetectorDescription.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 07/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "SendingView+DetectorDescription.h"

@implementation SendingView (DetectorDescription)

- (void) initializeForTraining
{
    //SENDING VIEW initialization
    self.progressView.hidden = NO;
    [self.progressView setProgress:0 animated:YES];
    self.hidden = NO;
    [self.activityIndicator startAnimating];
    self.cancelButton.hidden = NO;
    self.sendingViewID = @"train";
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancelling..." forState:UIControlStateDisabled];
    [self clearScreen];
}


- (void) stopAfterTraining
{
    //stop sending view
    [self.activityIndicator stopAnimating];
    [self.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
    self.sendingViewID = @"info";
    self.cancelButton.enabled = YES;
    self.cancelButton.hidden = NO;
}

- (void) initializeForInfoOfDetector:(Detector *) detector
{
    self.sendingViewID = @"info";
    [self.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
    self.hidden = NO;
    self.cancelButton.hidden = NO;
    self.progressView.hidden = YES;
    self.activityIndicator.hidden = YES;
    [self clearScreen];
    [self showMessage:[NSString stringWithFormat:@"Detector %@", detector.name]];
    [self showMessage:[NSString stringWithFormat:@"Number of images:%d", detector.imagesUsedTraining.count]];
    [self showMessage:[NSString stringWithFormat:@"Number of Support Vectors:%@", detector.numberSV]];
    [self showMessage:[NSString stringWithFormat:@"Number of positives %@", detector.numberOfPositives]];
    [self showMessage:[NSString stringWithFormat:@"HOG Dimensions:%@ x %@",[detector.sizes objectAtIndex:0],[detector.sizes objectAtIndex:1] ]];
    [self showMessage:@"**** Results on the training set ****"];
    [self showMessage:[NSString stringWithFormat:@"Precision:%.1f",[(NSNumber *)[detector.precisionRecall objectAtIndex:0] floatValue]]];
    [self showMessage:[NSString stringWithFormat:@"Recall:%.1f", [(NSNumber *)[detector.precisionRecall objectAtIndex:1] floatValue]]];
    [self showMessage:[NSString stringWithFormat:@"Time learning:%.1f", detector.timeLearning.floatValue]];
}

@end
