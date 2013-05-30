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


@protocol TagViewControllerDelegate <NSObject>

- (void) reloadTableOnImageGallery;

@end


@interface TagViewController : UIViewController <UIActionSheetDelegate, TagViewDelegate, UIScrollViewDelegate, ServerConnectionDelegate,UITableViewDataSource,UITableViewDelegate,SendingViewDelegate,UITextFieldDelegate, UIGestureRecognizerDelegate>
{
    BOOL keyboardVisible;
    ServerConnection *sConnection;
}

//views
@property (strong,nonatomic) SendingView *sendingView;
@property (strong, nonatomic) TagView *annotationView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UITextField *label;
@property (nonatomic, strong) UIImageView *imageView;
@property (strong, nonatomic) UITableView *labelsView;
@property (strong,nonatomic) UIView *composeView;
@property (strong, nonatomic) UIButton *tip;
@property (strong, nonatomic) id<TagViewControllerDelegate> delegate;

//toolbar
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (strong, nonatomic) IBOutlet UIButton *labelsButton;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;

//model
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSArray *paths;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSArray *items;
@property (strong, nonatomic) NSMutableDictionary *userDictionary;


- (void) keyboardDidShow:(NSNotification *)notif;
- (void) keyboardDidHide:(NSNotification *)notif;

-(IBAction)addAction:(id)sender;
-(IBAction)labelFinish:(id)sender;
-(IBAction)labelAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)doneAction:(id)sender;
-(IBAction)listAction:(id)sender;
-(IBAction)hideTip:(id)sender;

-(void)saveThumbnail;
-(void)saveDictionary;

@end
