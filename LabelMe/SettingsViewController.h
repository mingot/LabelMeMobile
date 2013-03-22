//
//  SettingsViewController.h
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebsiteViewController.h"

@interface SettingsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    UITableView *_tableView;
    NSString *_username;
    UIPopoverController *_popover;
    WebsiteViewController *_website;
    
}
@property (nonatomic,retain)  UITableView *tableView;
@property (nonatomic,retain) NSString *username;
@property (nonatomic,retain) UIPopoverController *popover;
@property (nonatomic,retain) WebsiteViewController *website;



-(IBAction)logOutAction:(id)sender;
@end
