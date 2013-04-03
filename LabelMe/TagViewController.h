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


@interface TagViewController : UIViewController <UIActionSheetDelegate, TagViewDelegate, UIScrollViewDelegate, ServerConnectionDelegate,UITableViewDataSource,UITableViewDelegate,SendingViewDelegate,UITextFieldDelegate>
{
    
     UIScrollView *         _scrollView;
     UITextField *          _label;
     UIBarButtonItem *      _addButton;
     UIBarButtonItem *      _deleteButton;
     UIBarButtonItem *      _sendButton;
    UIBarButtonItem *       _flexibleSpace;
    UIImageView *                   _imageView;
    //NSArray *                       _colorArray;
    NSString *                      _filename;
    NSArray *                       _paths;
    TagView *                       _annotationView;
    int numImages;
    BOOL                             keyboardVisible;
    //BOOL                             gallery;
    NSString * _username;
    
    UIView              *_composeView;
    UIBarButtonItem  *_labelsButton;
    CGSize              labelSize;
    UIToolbar           *_bottomToolbar;
    UITableView *_labelsView;
    SendingView *_sendingView;
    ServerConnection *sConnection;
    UIButton *labelsButtonView;
    UIButton *tip;
  
}

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UITextField *label;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic)  UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *labelsButton;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, strong) UIImageView *imageView;
@property (strong, nonatomic)  UITableView *labelsView;

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSArray *paths;
@property (strong, nonatomic)  TagView *annotationView;
@property (strong,nonatomic) NSString *username;
@property (strong,nonatomic) UIView *composeView;
@property (strong,nonatomic) SendingView *sendingView;


- (void) keyboardDidShow:(NSNotification *)notif;
- (void) keyboardDidHide:(NSNotification *)notif;

-(IBAction)addAction:(id)sender;
-(IBAction)labelFinish:(id)sender;
-(IBAction)labelAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)doneAction:(id)sender;
-(IBAction)listAction:(id)sender;

-(void)setImage:(UIImage *)image;
-(BOOL)saveThumbnail;
-(void)saveImage:(UIImage *)image;
-(BOOL)saveDictionary;
-(void)createFilename;
-(void)saveAnnotation;

@end
