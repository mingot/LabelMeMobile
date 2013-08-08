//
//  GalleryViewController.h
//  LabelMe
//
//  Created by Dolores on 28/09/12.
//  Updated by Josep Marc Mingot.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "TagViewController.h"
#import "CameraViewController.h"
#import "ModalSectionsTVC.h"
#import "ServerConnection.h"
#import "SendingView.h"
#import "AYUIButton.h"


@interface GalleryViewController : UIViewController <UIActionSheetDelegate,ServerConnectionDelegate, UITableViewDelegate,UITableViewDataSource,UINavigationControllerDelegate,SendingViewDelegate, ModalSectionsTVCDelegate, CameraViewControllerDeledate, TagViewControllerDelegate>


//model
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSArray *userPaths;

//controllers
@property (nonatomic, strong) TagViewController *tagViewController;
@property (nonatomic, strong) CameraViewController *cameraVC;
@property (nonatomic, strong) ModalSectionsTVC *modalSectionsTVC;

//view
@property (nonatomic, weak) IBOutlet UILabel *noImages;
@property (nonatomic, strong) SendingView *sendingView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic, strong) IBOutlet UIButton *listButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UITableView *tableViewGrid;
@property (nonatomic, weak) IBOutlet AYUIButton *downloadButton;
@property (nonatomic, weak) IBOutlet AYUIButton *cameraButton;



//actions
-(IBAction)buttonClicked:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)listAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)editAction:(id)sender;
-(IBAction)addImage:(id)sender;
-(IBAction)downloadAction:(id)sender;


@end
