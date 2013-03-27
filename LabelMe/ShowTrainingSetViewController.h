//
//  ShowTrainingSetViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 27/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShowImageViewController.h"


@interface ShowTrainingSetViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>


@property (strong, nonatomic) NSArray *listOfImages;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) ShowImageViewController *imageController;


@end
