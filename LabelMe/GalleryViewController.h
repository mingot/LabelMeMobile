//
//  GalleryViewController.h
//  LabelMe
//
//  Created by Dolores on 28/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TagViewController.h"
#import "ServerConnection.h"
#import "SendingView.h"
#import "ModalTVC.h"
#import "CameraViewController.h"
#import "LogVC.h"

@interface GalleryViewController : UIViewController <UIActionSheetDelegate,ServerConnectionDelegate, UITableViewDelegate,UITableViewDataSource,UINavigationControllerDelegate,SendingViewDelegate, ModalTVCDelegate, CameraViewControllerDeledate, LogVCDelegate>
{    
    ServerConnection *serverConnection;
    SendingView *sendingView;

    UILabel *noImages;
    int selectedTableIndex;
    int photosWithErrors;
    IBOutlet UIView *view1;
}


@property (nonatomic,strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic,strong) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic,strong) IBOutlet UILabel *usernameLabel;
@property (nonatomic,strong) IBOutlet UIImageView *profilePicture;
@property (nonatomic,strong) IBOutlet UIButton *listButton;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UITableView *tableViewGrid;


@property (nonatomic,strong) NSArray *paths;
@property (nonatomic,strong) NSArray *items;

@property (nonatomic,strong) NSMutableArray *selectedItems;
@property (nonatomic,strong) NSMutableArray *selectedItemsSend;
@property (nonatomic,strong) NSMutableArray *selectedItemsDelete;

@property (nonatomic,strong) TagViewController *tagViewController;
@property (nonatomic,strong) CameraViewController *cameraVC;
@property (nonatomic,strong) ModalTVC *modalTVC;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSArray *userPaths;



@property (nonatomic,strong) CLLocationManager *locationMng;

-(IBAction)buttonClicked:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)listAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)editAction:(id)sender;
-(IBAction)moreImagesAction:(id)sender;
-(IBAction)addImage:(id)sender;


@end
