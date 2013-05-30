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
#import "CameraViewController.h"
#import "ModalSectionsTVC.h"
#import "ServerConnection.h"
#import "SendingView.h"
#import "AYUIButton.h"


@interface GalleryViewController : UIViewController <UIActionSheetDelegate,ServerConnectionDelegate, UITableViewDelegate,UITableViewDataSource,UINavigationControllerDelegate,SendingViewDelegate, ModalSectionsTVCDelegate, CameraViewControllerDeledate, TagViewControllerDelegate>
{
    int selectedTableIndex;
    int photosWithErrors;
    
}


@property (nonatomic,strong) ServerConnection *serverConnection;
@property (nonatomic,strong) CLLocationManager *locationMng;
@property (nonatomic,strong) NSArray *paths;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSArray *userPaths;
@property (nonatomic,strong) NSMutableDictionary *userDictionary;

//view
@property (nonatomic, strong) UILabel *noImages;
@property (nonatomic, strong) SendingView *sendingView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic,strong) IBOutlet UIButton *listButton;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UITableView *tableViewGrid;
@property (weak, nonatomic) IBOutlet AYUIButton *downloadButton;
@property (weak, nonatomic) IBOutlet AYUIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

//table
@property (nonatomic,strong) NSArray *items;
@property (nonatomic,strong) NSMutableArray *selectedItems;
@property (nonatomic,strong) NSMutableArray *selectedItemsSend;
@property (nonatomic,strong) NSMutableArray *selectedItemsDelete;

//controllers
@property (nonatomic,strong) TagViewController *tagViewController;
@property (nonatomic,strong) CameraViewController *cameraVC;
@property (nonatomic,strong) ModalSectionsTVC *modalSectionsTVC;

//actions
-(IBAction)buttonClicked:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)listAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)editAction:(id)sender;
//-(IBAction)imageSelectedAction:(UIButton *)button;
-(IBAction)addImage:(id)sender;
-(IBAction)downloadAction:(id)sender;


@end
