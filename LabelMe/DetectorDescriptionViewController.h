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
#import "ShowTrainingSetViewController.h"

@interface DetectorDescriptionViewController : UIViewController


@property (strong, nonatomic) TrainDetectorViewController *trainController;
@property (strong, nonatomic) ExecuteDetectorViewController *executeController;
@property (strong, nonatomic) Classifier *svmClassifier;
@property (strong, nonatomic) NSString *classifierName;
@property (strong, nonatomic) NSString *classToLearn;
@property (weak, nonatomic) IBOutlet UIButton *executeButton;
@property (weak, nonatomic) IBOutlet UILabel *classifierNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *classToLearnLabel;

@property (strong, nonatomic) ShowTrainingSetViewController *trainingSetController;


- (IBAction)trainAction:(id)sender;
- (IBAction)executeAction:(id)sender;
- (IBAction)trainFromSetAction:(id)sender;



@end
