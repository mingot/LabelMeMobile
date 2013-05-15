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
#import "ModalSectionsTVC.h"

#import "CameraViewController.h"

@interface GalleryViewController : UIViewController <UIActionSheetDelegate,ServerConnectionDelegate, UITableViewDelegate,UITableViewDataSource,UINavigationControllerDelegate,SendingViewDelegate, ModalTVCDelegate, ModalSectionsTVCDelegate, CameraViewControllerDeledate>
{
    int selectedTableIndex;
    int photosWithErrors;
    
}


@property (nonatomic, strong) ServerConnection *serverConnection;
@property (nonatomic,strong) CLLocationManager *locationMng;
@property (nonatomic,strong) NSArray *paths;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSArray *userPaths;

//view
@property (nonatomic, strong) UILabel *noImages;
@property (nonatomic, strong) SendingView *sendingView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic,strong) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem *sendButton;
@property (nonatomic,strong) IBOutlet UIButton *listButton;
@property (nonatomic,strong) IBOutlet UITableView *tableView;
@property (nonatomic,strong) IBOutlet UITableView *tableViewGrid;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;



//table
@property (nonatomic,strong) NSArray *items;
@property (nonatomic,strong) NSMutableArray *selectedItems;
@property (nonatomic,strong) NSMutableArray *selectedItemsSend;
@property (nonatomic,strong) NSMutableArray *selectedItemsDelete;


@property (nonatomic,strong) TagViewController *tagViewController;
@property (nonatomic,strong) CameraViewController *cameraVC;
@property (nonatomic,strong) ModalTVC *modalTVC;
@property (nonatomic,strong) ModalSectionsTVC *modalSectionsTVC;


-(IBAction)buttonClicked:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)listAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)editAction:(id)sender;
-(IBAction)moreImagesAction:(id)sender;
-(IBAction)imageSelectedAction:(UIButton *)button;
-(IBAction)addImage:(id)sender;
-(IBAction)downloadAction:(id)sender;


@end
