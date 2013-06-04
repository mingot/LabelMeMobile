//
//  ResolutionViewController.h
//  LabelMe
//
//  Created by Dolores on 17/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResolutionViewController : UIViewController <UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSString *username;

@end
