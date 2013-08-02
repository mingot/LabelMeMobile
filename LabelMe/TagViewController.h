//
//  TagViewController.h
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagView.h"
#import "Box.h"
#import "ServerConnection.h"
#import "SendingView.h"
#import "TagImageView.h"

@protocol TagViewControllerDelegate <NSObject>

- (void) reloadTableForFilename:(NSString *)filename;

@end


@interface TagViewController : UIViewController <UIActionSheetDelegate, TagViewDelegate, ServerConnectionDelegate,UITableViewDataSource,UITableViewDelegate,SendingViewDelegate>


//views
@property (weak, nonatomic) IBOutlet TagImageView *tagImageView;

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

//@property (strong, nonatomic) NSArray *paths;
@property (strong, nonatomic) NSArray *items;
//@property (strong, nonatomic) NSMutableDictionary *userDictionary;



-(IBAction)addAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)listAction:(id)sender;

-(IBAction)hideTip:(id)sender;
-(IBAction)changeImageAction:(id)sender;

-(void)saveThumbnail;
-(void)saveDictionary;

@end
