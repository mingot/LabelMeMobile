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
#import "SendingView.h"
#import "Detector.h"
#import "DetectorResourceHandler.h"
#import "SelectionHandler.h"


@protocol DetectorDescriptionViewControllerDelegate <NSObject>

- (void) updateDetector:(Detector *)updatedDetector;

@end


/*
 
 Class  Responsabilities:
 
 - Manage actions of the bottom bar:
 - Call ExecuteDetectorVC
 - Train the detector
 - Undo to last train
 - Show info about the detector
 - Show and handle the introduction of data in the table view
 - Show/Hide keyboard and move view to not hide text input area
 
 
 */

@interface DetectorDescriptionViewController : UIViewController <SendingViewDelegate,DetectorDelegate, UIAlertViewDelegate, UITableViewDelegate,UITableViewDataSource, UITextFieldDelegate, ExecuteDetectorViewControllerDelegate, SelectionHandlerDelegate>


@property (strong, nonatomic) id <DetectorDescriptionViewControllerDelegate> delegate;
@property (strong, atomic) DetectorResourceHandler *detectorResourceHandler;
@property (strong, nonatomic) ExecuteDetectorViewController *executeController;
@property (strong, nonatomic) Detector *detector;

//views
@property (weak, nonatomic) IBOutlet UIImageView *detectorView;
@property (weak, nonatomic) IBOutlet UIImageView *detectorHogView;
@property (weak, nonatomic) IBOutlet UITableView *descriptionTableView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView; //for hide/show keyboard
@property (weak, nonatomic) IBOutlet UIView *containerView; //container for hide/show keyboard

//bottom toolbar
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolbar;



@end




