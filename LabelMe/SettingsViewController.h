//
//  SettingsViewController.h
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebsiteViewController.h"

@interface SettingsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) UIPopoverController *popover;
@property (nonatomic,strong) WebsiteViewController *website;



-(IBAction)logOutAction:(id)sender;
-(IBAction)profilePictureAction:(id)sender;
-(IBAction)valueDidChange:(id)sender;
-(IBAction)stepperDidChange:(id)sender;

@end
