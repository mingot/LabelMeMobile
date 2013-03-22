//
//  DetectorGalleryViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetectorGalleryViewController : UIViewController <UINavigationControllerDelegate,UITableViewDelegate,UITableViewDataSource>


@property (nonatomic, strong) NSMutableArray *detectors;
@property (weak, nonatomic) IBOutlet UITableView *tableView;



- (IBAction) Edit:(id)sender;

@end


