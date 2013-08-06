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
#import "ModalTVC.h"
#import "SendingView.h"
#import "Classifier.h"
#import "DetectorResourceHandler.h"

@protocol DetectorDescriptionViewControllerDelegate <NSObject>

- (void) updateClassifier:(Classifier *)updatedClassifier;

@end



@interface DetectorDescriptionViewController : UIViewController <SendingViewDelegate,ClassifierDelegate,ModalTVCDelegate, UIAlertViewDelegate, UITableViewDelegate,UITableViewDataSource, UITextFieldDelegate, ExecuteDetectorViewControllerDelegate>

@property (strong, nonatomic) id <DetectorDescriptionViewControllerDelegate> delegate;

@property (strong, nonatomic) ExecuteDetectorViewController *executeController;
@property (strong, nonatomic) ModalTVC *modalTVC;
@property (strong, nonatomic) SendingView *sendingView;

//array with the properties to show in the description
@property (strong, nonatomic) NSMutableArray *classifierProperties;
@property (strong, nonatomic) Classifier *svmClassifier;
@property (strong, nonatomic) Classifier *previousSvmClassifier; //to undo

//views
@property (weak, nonatomic) IBOutlet UIImageView *detectorView;
@property (weak, nonatomic) IBOutlet UIImageView *detectorHogView;
@property (strong, nonatomic) UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UITableView *descriptionTableView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView; //for hide/show keyboard
@property (weak, nonatomic) IBOutlet UIView *showView;

//bottom toolbar
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (strong, nonatomic) UIBarButtonItem *executeButtonBar;
@property (strong, nonatomic) UIBarButtonItem *trainButtonBar;
@property (strong, nonatomic) UIBarButtonItem *infoButtonBar;
@property (strong, nonatomic) UIBarButtonItem *undoButtonBar;

//useful information
@property (strong, nonatomic) DetectorResourceHandler *detectorResourceHandler;
//@property (strong, nonatomic) NSString *userPath;
//@property (strong, nonatomic) NSArray *resourcesPaths;
@property (strong, nonatomic) NSArray *availableObjectClasses;
//@property (strong, nonatomic) NSArray *availablePositiveImagesNames;
@property (strong, nonatomic) NSMutableArray *selectedPositiveImageIndexes;
@property (strong, nonatomic) NSMutableArray *selectedPostiveImageNames; //to save with the svm


- (IBAction)executeAction:(id)sender;
- (IBAction)trainAction:(id)sender;
- (IBAction)infoAction:(id)sender;
- (IBAction)undoAction:(id)sender;
- (IBAction)saveAction:(id)sender;


@end




