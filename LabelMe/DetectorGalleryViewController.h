//
//  DetectorGalleryViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetectorDescriptionViewController.h"
#import "Classifier.h"

@interface DetectorGalleryViewController : UIViewController <UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource,DetectorDescriptionViewControllerDelegate>
{
    NSInteger _selectedRow;
}

@property (nonatomic, strong) NSMutableArray *detectors; //Classifier
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) DetectorDescriptionViewController *detectorController;
@property (nonatomic, strong) NSString *userPath;
@property (nonatomic, strong) NSString *username;



- (IBAction) Edit:(id)sender;

@end


