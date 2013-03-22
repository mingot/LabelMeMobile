//
//  GalleryViewController.h
//  LabelMe
//
//  Created by Dolores on 28/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagViewController.h"
#import "ServerConnection.h"
#import "SendingView.h"

@interface GalleryViewController : UIViewController <UIActionSheetDelegate,ServerConnectionDelegate, UITableViewDelegate,UITableViewDataSource,UINavigationControllerDelegate,SendingViewDelegate>{
    
    
    UIBarButtonItem             *_editButton;
    UIToolbar                   *_bottomToolbar;
    UIBarButtonItem             *_deleteButton;
    UIBarButtonItem             *_sendButton;

    UILabel                     *_usernameLabel;
    UIImageView                 *_profilePicture;


    UIButton                    *_listButton;
    
    
    NSArray                     *_paths;
    NSArray                     *_items;
    
    
    NSMutableArray              *_selectedItems;
    NSMutableArray              *_selectedItemsSend;
    NSMutableArray              *_selectedItemsDelete;

    UITableView                 *_tableView;
    UITableView                 *_tableViewGrid;

    NSString                    *_username;
       
    TagViewController           *_tagViewController;
    ServerConnection            *serverConnection;
    SendingView                 *sendingView;

    UILabel                     *noImages;
    //UIButton                *sendTable;
    int                          selectedTableIndex;
    int                         photosWithErrors;
    
    IBOutlet UIView                      *view1;
}
@property (nonatomic,retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic,retain) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *deleteButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *sendButton;

@property (nonatomic,retain) IBOutlet UILabel *usernameLabel;
@property (nonatomic, retain) IBOutlet UIImageView *profilePicture;

@property (nonatomic,retain) IBOutlet UIButton *listButton;

@property (nonatomic,retain) NSArray *paths;
@property (nonatomic,retain) NSArray *items;

@property (nonatomic,retain) NSMutableArray *selectedItems;
@property (nonatomic,retain) NSMutableArray *selectedItemsSend;
@property (nonatomic,retain) NSMutableArray *selectedItemsDelete;

@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (nonatomic,retain) IBOutlet UITableView *tableViewGrid;

@property (nonatomic,retain) TagViewController *tagViewController;


@property (nonatomic,retain) NSString *username;






-(IBAction)buttonClicked:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)listAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)editAction:(id)sender;

@end
