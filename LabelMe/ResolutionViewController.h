//
//  ResolutionViewController.h
//  LabelMe
//
//  Created by Dolores on 17/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResolutionViewController : UIViewController <UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>{
    UITableView *_tableView;
    NSString *_username;
}

@property (nonatomic,retain) UITableView *tableView;
@property (nonatomic,retain) NSString *username;

@end
