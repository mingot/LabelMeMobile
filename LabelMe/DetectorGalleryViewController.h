//
//  DetectorGalleryViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetectorDescriptionViewController.h"
#import "ModalTVC.h"
#import "ExecuteDetectorViewController.h"
#import "Classifier.h"


@interface DetectorGalleryViewController : UIViewController <UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,DetectorDescriptionViewControllerDelegate>
{
    NSInteger _selectedRow;
}

@property (nonatomic, strong) DetectorDescriptionViewController *detectorController;
@property (nonatomic, strong) ModalTVC *modalTVC;
@property (nonatomic, strong) ExecuteDetectorViewController *executeDetectorVC;

//detecotrs
@property (nonatomic, strong) NSMutableArray *detectors;
@property (nonatomic, strong) NSMutableArray *selectedItems;

//view
@property (weak, nonatomic) IBOutlet UILabel *noImages;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIBarButtonItem *editButton;
@property (strong, nonatomic) UIButton *executeDetectorsButton;
@property (strong, nonatomic) UIBarButtonItem *plusButton;
@property (strong, nonatomic) UIBarButtonItem *deleteButton;
@property (strong, nonatomic) UIBarButtonItem *executeButton;

//resources
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *userPath;
@property (strong, nonatomic) NSArray *resourcesPaths;
@property (strong, nonatomic) NSArray *availableObjectClasses;

//top toolbar actions
- (IBAction) edit:(id)sender;
- (IBAction) addDetector:(id)sender;
- (IBAction) executeDetectorsAction:(id)sender;

@end


