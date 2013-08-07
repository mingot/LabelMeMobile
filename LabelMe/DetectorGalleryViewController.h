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
#import "detector.h"
#import "DetectorResourceHandler.h"


/*
 
 Class  Responsabilities:
 
 - Present the current detectors and connect with the DetectorDescriptionVC
 - Add and delete detecotrs
 - Choose and execute multiple detectors at the same time
 
 */

@interface DetectorGalleryViewController : UIViewController <UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,DetectorDescriptionViewControllerDelegate>

//controllers connections
@property (nonatomic, strong) DetectorDescriptionViewController *detectorController;
@property (nonatomic, strong) ExecuteDetectorViewController *executeDetectorVC;

//view
@property (weak, nonatomic) IBOutlet UILabel *noImages;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//resources
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) DetectorResourceHandler *detectorResourceHandler;

@end


