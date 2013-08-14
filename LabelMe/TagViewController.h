//
//  TagViewController.h
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Updated by Josep Marc Mingot.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InfiniteLoopView.h"
#import "TagImageView.h"
#import "TagView.h"
#import "Box.h"
#import "ServerConnection.h"
#import "SendingView.h"
#import "KeyboardHandler.h"



@protocol TagViewControllerDelegate <NSObject>

- (void) reloadTable;

@end



/*
 
 Class  Responsibilities:
 
 - Loading images and boxes from HD
 - Handle actions from bottom menu bar: new label, delete label, send label, show labels
 - Show a usage tip the first time the app runs
 - When a box has been modified, save state
 - Manage permissions of when the page scrolling is enabled in InfiniteLoopView
 - Attach to each TagView label a keyboard handler for the suggestions and moving.
 
 */

@interface TagViewController : UIViewController <UIActionSheetDelegate, TagViewDelegate, ServerConnectionDelegate,UITableViewDataSource,UITableViewDelegate,SendingViewDelegate, InfiniteLoopDataSoruce, InfiniteLoopDelegate, TagImageViewDelegate,KeyboardHandlerDataSource>


//views
@property (strong, nonatomic) TagImageView *tagImageView;
@property (weak, nonatomic) IBOutlet InfiniteLoopView *infiniteLoopView;

@property (strong, nonatomic) id<TagViewControllerDelegate> delegate;

//toolbar
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *labelsButtonItem;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;

//model
@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSArray *imageFilenames;



- (IBAction)addAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)sendAction:(id)sender;
- (IBAction)listAction:(id)sender;

- (IBAction)hideTip:(id)sender;


@end
