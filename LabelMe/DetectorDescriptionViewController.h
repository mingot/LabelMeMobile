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


@protocol DetectorDescriptionViewControllerDelegate <NSObject>

- (void) updateDetector:(Classifier *)updatedDetector;

@end



@interface DetectorDescriptionViewController : UIViewController


@property (strong, nonatomic) ExecuteDetectorViewController *executeController;
@property (strong, nonatomic) ShowTrainingSetViewController *trainingSetController;
@property (strong, nonatomic) Classifier *svmClassifier;

@property (weak, nonatomic) IBOutlet UIButton *executeButton;
@property (weak, nonatomic) IBOutlet UIButton *trainButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIImageView *detectorView;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *classTextField;

@property (strong, nonatomic) NSString *userPath;
@property (strong, nonatomic) id <DetectorDescriptionViewControllerDelegate> delegate;




- (IBAction)executeAction:(id)sender;
- (IBAction)trianAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
