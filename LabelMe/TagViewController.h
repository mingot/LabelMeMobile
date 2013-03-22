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


@interface TagViewController : UIViewController <UIActionSheetDelegate, TagViewDelegate, UIScrollViewDelegate, ServerConnectionDelegate,UITableViewDataSource,UITableViewDelegate,SendingViewDelegate,UITextFieldDelegate>{
    
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
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UITextField *label;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (retain, nonatomic)  UIBarButtonItem *deleteButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *labelsButton;
@property (retain, nonatomic) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, retain) UIImageView *imageView;
@property (retain, nonatomic)  UITableView *labelsView;

//@property (retain, nonatomic) NSArray *colorArray;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSArray *paths;
@property (retain, nonatomic)  TagView *annotationView;
@property (retain,nonatomic) NSString *username;
@property (retain,nonatomic) UIView *composeView;
@property (retain,nonatomic) SendingView *sendingView;





//@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;


- (void) keyboardDidShow:(NSNotification *)notif;
- (void) keyboardDidHide:(NSNotification *)notif;

-(IBAction)addAction:(id)sender;
-(IBAction)labelFinish:(id)sender;
-(IBAction)labelAction:(id)sender;
-(IBAction)deleteAction:(id)sender;
-(IBAction)sendAction:(id)sender;
-(IBAction)doneAction:(id)sender;
-(IBAction)listAction:(id)sender;


//-(void) setGallery:(BOOL)value;
-(void)setImage:(UIImage *)image;
-(BOOL)saveThumbnail;
-(void)saveImage:(UIImage *)image;
-(BOOL)saveDictionary;
-(void)createFilename;
-(void)saveAnnotation;

@end
