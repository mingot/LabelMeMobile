//
//  DetectirDescriptionViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrainDetectorViewController.h"
#import "ExecuteDetectorViewController.h"

@interface DetectorDescriptionViewController : UIViewController


@property (strong, nonatomic) TrainDetectorViewController *trainController;
@property (strong, nonatomic) ExecuteDetectorViewController *executeController;


- (IBAction)trainAction:(id)sender;
- (IBAction)executeAction:(id)sender;



@end
