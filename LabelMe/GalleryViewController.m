//
//  GalleryViewController.m
//  LabelMe
//
//  Created by Dolores on 28/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "GalleryViewController.h"
#import "Constants.h"
#import "NSObject+Folders.h"
#import "Box.h"
#import "ServerConnection.h"
#import <QuartzCore/QuartzCore.h>
#import "CustomBadge.h"
#import "UIImage+Resize.h"
#import "NSObject+ShowAlert.h"
#import "QuartzCore/CALayer.h"


@interface GalleryViewController ()

@end

@implementation GalleryViewController
@synthesize editButton = _editButton;
@synthesize bottomToolbar = _bottomToolbar;
@synthesize deleteButton = _deleteButton;
@synthesize sendButton = _sendButton;
@synthesize usernameLabel = _usernameLabel;

@synthesize listButton = _listButton;
@synthesize paths = _paths;
@synthesize items = _items;
@synthesize selectedItems = _selectedItems;
@synthesize selectedItemsSend = _selectedItemsSend;
@synthesize selectedItemsDelete = _selectedItemsDelete;
@synthesize tagViewController = _tagViewController;
@synthesize tableView = _tableView;
@synthesize tableViewGrid = _tableViewGrid;
@synthesize username = _username;
#pragma mark -
#pragma mark Initialization Method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.items = [[NSArray alloc] init];
        self.tabBarItem= [[UITabBarItem alloc]initWithTitle:@"Home" image:nil tag:0];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"home.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"homeActive.png"]];
        self.selectedItems = [[NSMutableArray alloc]init];
        self.selectedItemsSend = [[NSMutableArray alloc]init];
        self.selectedItemsDelete = [[NSMutableArray alloc]init];
        self.username = [[NSString alloc] init];
        serverConnection = [[ServerConnection alloc] init];

        self.sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendAction:)];
        self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteAction:)];
        self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editAction:)];
        serverConnection.delegate = self;

            }
    return self;
}
#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.usernameLabel setText:self.username];
    [self.usernameLabel setTextColor:[UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0]];
    //[self.usernameLabel setTextColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    // TitleView: LabelMe Logo
    UIImage *titleImage = [UIImage imageNamed:@"logo-title.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    [titleView setImage:titleImage];
    [self.navigationItem setTitleView:titleView];
    //[titleImage release];

    UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"] ;
    //[self.view setBackgroundColor:[UIColor colorWithRed:236/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    //[self.editButton setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    [self.editButton setStyle:UIBarButtonItemStyleBordered];
    [self.navigationItem setRightBarButtonItem:self.editButton];

   // self.sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendAction:)];
    //[self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.deleteButton,self.sendButton, nil]];
    [self.deleteButton setTintColor:[UIColor redColor]];
    [self.deleteButton setWidth:self.view.frame.size.width/2 - 11];
    [self.sendButton setWidth:self.view.frame.size.width/2 - 11];
    [self.deleteButton setEnabled:NO];
    [self.sendButton setEnabled:NO];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.navigationController.navigationBar setBackgroundImage:barImage forBarMetrics:UIBarMetricsDefault];


    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];

    self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        
        if (screenSize.size.height == 568) {
            
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone5" bundle:nil];
            
        }
        else if (screenSize.size.height == 480){
            
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone" bundle:nil];
            
        }
        
        
        
    }
    else{
        self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPad" bundle:nil];

    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height+2, self.view.frame.size.width, self.view.frame.size.height-self.navigationController.navigationBar.frame.size.height-2) style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:nil];
    self.tableView.hidden = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setRowHeight:self.view.frame.size.width/4];
    [self.tableView setTag:1];
    [self.listButton setImage:[UIImage imageNamed:@"listC.png"] forState:UIControlStateNormal];
    [self.listButton setImage:[UIImage imageNamed:@"gridC.png"] forState:UIControlStateSelected];
    self.tableViewGrid = [[UITableView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height+2, self.view.frame.size.width, self.view.frame.size.height-self.navigationController.navigationBar.frame.size.height-2) style:UITableViewStyleGrouped];
    self.tableViewGrid.backgroundColor = [UIColor clearColor];
    [self.tableViewGrid setBackgroundView:nil];
    self.tableViewGrid.delegate = self;
    self.tableViewGrid.dataSource = self;
    [self.tableViewGrid setTag:0];
    
    noImages = [[UILabel alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x+0.03125*self.view.frame.size.width, self.tableView.frame.origin.y+0.03125*self.view.frame.size.width, self.tableView.frame.size.width-0.0625*self.view.frame.size.width, self.tableView.frame.size.height-0.0625*self.view.frame.size.width)];
    [noImages setBackgroundColor:[UIColor whiteColor]];
    noImages.layer.masksToBounds = YES;
    noImages.layer.cornerRadius = 10.0;
    noImages.layer.shadowColor = [UIColor grayColor].CGColor;
    noImages.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    noImages.shadowColor = [UIColor grayColor];
    [noImages setNumberOfLines:2];
    noImages.shadowOffset = CGSizeMake(0.0, 1.0);
    noImages.text = @"You do not have images, \nstart taking pics and labeling!";
    [noImages setTextAlignment:NSTextAlignmentCenter];
    sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    [sendingView setHidden:YES];
    [self.tabBarController.tabBar setUserInteractionEnabled:YES];

    sendingView.delegate = self;
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.tableViewGrid];
    [self.view addSubview:noImages];
    [self.view addSubview:sendingView];
    photosWithErrors = 0;
    self.profilePicture = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, view1.frame.size.width, view1.frame.size.height)];
    self.profilePicture.layer.masksToBounds = YES;
    self.profilePicture.layer.cornerRadius = 6.0;
    [self.profilePicture setContentMode:UIViewContentModeScaleAspectFit];

    //[self.profilePicture setBackgroundColor:[UIColor clearColor]];
    [view1.layer setShadowColor:[UIColor blackColor].CGColor];
    [view1.layer setShadowOffset:CGSizeMake(0, 1)];
    [view1.layer setShadowOpacity:0.9];
    [view1.layer setShadowRadius:3.0];
    [view1.layer setCornerRadius:6.0];
    [view1 addSubview:self.profilePicture];
    [view1 setClipsToBounds:NO];
    
    // Do any additional setup after loading the view from its nib.
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    NSFileManager * filemng = [NSFileManager defaultManager];

    if ([filemng fileExistsAtPath:[[self.paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]]) {
        
        [self.profilePicture setImage:[UIImage imageWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]] ];
    }
    else{
        [self.profilePicture setImage:[UIImage imageNamed:@"silueta.png"]];
    }

    
    [self reloadGallery];
}
- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.editButton.title == @"Cancel") {
        [self.editButton setTitle:@"Edit"];
        [self.editButton setStyle:UIBarButtonItemStyleBordered];
        
        [self.listButton setHidden:NO];
        [self.sendButton setTitle:@"Send"];
        [self.deleteButton setTitle:@"Delete"];
        [self.selectedItems removeAllObjects];
        [self.sendButton setEnabled:NO];
        [self.deleteButton setEnabled:NO];
        [self.tableViewGrid setFrame:CGRectMake(self.tableViewGrid.frame.origin.x, self.tableViewGrid.frame.origin.y, self.tableViewGrid.frame.size.width, self.tableViewGrid.frame.size.height + self.navigationController.toolbar.frame.size.height)];
        
        //[self.tabBarController.tabBar setHidden:NO];
        
        //[self.navigationController setToolbarHidden:YES];
        //[self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height -  self.tabBarController.tabBar.frame.size.height)];
        [self.navigationController setToolbarHidden:YES];
    }
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self reloadGallery];


}
#pragma mark -
#pragma mark Gallery Management

-(void) reloadGallery{
    NSFileManager * filemng = [NSFileManager defaultManager];
    [self setItems:[filemng contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.paths objectAtIndex:THUMB]] error:NULL]];
    [self.tableViewGrid setRowHeight:(0.225*self.view.frame.size.width*ceil((float)self.items.count/4) +0.0375*self.view.frame.size.width)];
    [self.tableView reloadData];
    [self.tableViewGrid reloadData];
    if (self.items.count == 0) {
        [noImages setHidden:NO];
    }
    else{
        [noImages setHidden:YES];
    }

}
-(UIView *)correctAccessoryAtIndex:(int)i withNum:(NSNumber *)num withSize:(CGSize)size{
    UIView *ret = nil;
    CGSize size2 = size;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        size2 = CGSizeMake(80, 80);
        
    }

    if (num.intValue < 0) {
        NSString *numBadge= [[NSString alloc] initWithFormat:@"%d",abs(num.intValue+1)];
        CustomBadge *accessory = [CustomBadge customBadgeWithString:numBadge withStringColor:[UIColor whiteColor] withInsetColor:[UIColor redColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor] withScale:1.0 withShining:YES];
        [accessory setFrame:CGRectMake(size.width- 0.30*size2.width, 0, 0.30*size2.width, 0.30*size2.width)];
        ret = accessory;
    }
    else if (num.intValue == 0){
        UIImageView *accessory =  [[UIImageView alloc] initWithFrame:CGRectMake(size.width- 0.25*size2.width, 0, 0.25*size2.width, 0.25*size2.width)];
        accessory.image = [UIImage imageNamed:@"tick.png"];
        ret = accessory;

    }
    else{
        CustomBadge *accessory = [CustomBadge customBadgeWithString:num.stringValue withStringColor:[UIColor whiteColor] withInsetColor:[UIColor orangeColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor] withScale:1.0 withShining:YES];
        [accessory setFrame:CGRectMake(size.width- 0.30*size2.width, 0, 0.30*size2.width, 0.30*size2.width)];
        ret = accessory;
    }
    return  ret;
}
-(UIImage * ) addBorderTo:(UIImage *)image{
    CGImageRef bgimage = [image CGImage];
	float width = CGImageGetWidth(bgimage);
	float height = CGImageGetHeight(bgimage);
    // Create a temporary texture data buffer
	void *data = malloc(width * height * 4);
    
	// Draw image to buffer
	CGContextRef ctx = CGBitmapContextCreate(data,
                                             width,
                                             height,
                                             8,
                                             width * 4,
                                             CGImageGetColorSpace(image.CGImage),
                                             kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), bgimage);
	//Set the stroke (pen) color
	CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:(160/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0].CGColor);
    
	//Set the width of the pen mark
	CGFloat borderWidth = (float)self.view.frame.size.width*0.4125*0.075;
	CGContextSetLineWidth(ctx, borderWidth);
    
	//Start at 0,0 and draw a square
	/*CGContextMoveToPoint(ctx, borderWidth/2, 12-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2, 144-borderWidth/2);
	CGContextAddLineToPoint(ctx, 132-borderWidth/2, 144-borderWidth/2);
	CGContextAddLineToPoint(ctx, 132-borderWidth/2,12-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2, 12-borderWidth/2);
    */
    CGContextMoveToPoint(ctx, borderWidth/2, borderWidth/2);
	CGContextAddLineToPoint(ctx, self.view.frame.size.width*0.4125-borderWidth/2, borderWidth/2);
	CGContextAddLineToPoint(ctx, self.view.frame.size.width*0.4125-borderWidth/2, self.view.frame.size.width*0.4125-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2,self.view.frame.size.width*0.4125-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2, 0);
	//Draw it
	CGContextStrokePath(ctx);
    
    // write it to a new image
	CGImageRef cgimage = CGBitmapContextCreateImage(ctx);
	UIImage *newImage = [UIImage imageWithCGImage:cgimage];
	CFRelease(cgimage);
	CGContextRelease(ctx);
    free(data);
    
    // auto-released
	return newImage;
}
#pragma mark -
#pragma mark IBActions
-(IBAction)editAction:(id)sender{
    if (!self.listButton.isSelected) {
        if (self.editButton.title == @"Edit") {
            [self.listButton setHidden:YES];
            //[self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height +  49)];
            //[self.tabBarController.tabBar setHidden:YES];
            [self.editButton setTitle:@"Cancel"];
            [self.navigationController setToolbarHidden:NO];
            NSArray *toolbarItems = [[NSArray alloc] initWithObjects:self.sendButton,self.deleteButton, nil];
            [self.navigationController.toolbar setItems:toolbarItems];
            [self.tableViewGrid setFrame:CGRectMake(self.tableViewGrid.frame.origin.x, self.tableViewGrid.frame.origin.y, self.tableViewGrid.frame.size.width, self.tableViewGrid.frame.size.height - self.navigationController.toolbar.frame.size.height)];
            [self.editButton setStyle:UIBarButtonSystemItemCancel];
            
        }
        else{
            [self.editButton setTitle:@"Edit"];
            [self.editButton setStyle:UIBarButtonItemStyleBordered];
            [self.listButton setHidden:NO];
            [self.sendButton setTitle:@"Send"];
            [self.deleteButton setTitle:@"Delete"];
            [self.selectedItems removeAllObjects];
            [self.sendButton setEnabled:NO];
            [self.deleteButton setEnabled:NO];
            [self.tableViewGrid setFrame:CGRectMake(self.tableViewGrid.frame.origin.x, self.tableViewGrid.frame.origin.y, self.tableViewGrid.frame.size.width, self.tableViewGrid.frame.size.height + self.navigationController.toolbar.frame.size.height)];
            [self.navigationController setToolbarHidden:YES];
            [self reloadGallery];
            
        }
    }
    else{
        if (self.editButton.title == @"Edit") {
            [self.tableView setEditing:YES animated:YES];
            [self.listButton setHidden:YES];
            [self.editButton setTitle:@"Done"];
            [self.editButton setStyle:UIBarButtonSystemItemDone];

        }
        else{

            [self.tableView setEditing:NO animated:YES];
            [self.listButton setHidden:NO];
            [self.editButton setTitle:@"Edit"];
            [self.editButton setStyle:UIBarButtonItemStyleBordered];
            
        }
    }
    
}

-(IBAction)buttonClicked:(id)sender{
    
    UIButton *button = (UIButton *)sender;
    
    if (self.editButton.title == @"Cancel") {
        if ([self.selectedItems containsObject:[self.items objectAtIndex:abs(button.tag)-1]]) {
            [self.selectedItems removeObject:[self.items objectAtIndex:abs(button.tag)-1]];
            [button setSelected:NO];
        }
        else{
            [self.selectedItems addObject:[self.items objectAtIndex:abs(button.tag)-1]];
            [button setSelected:YES];
        }
        if (self.selectedItems.count > 0) {
            [self.sendButton setTitle:[NSString stringWithFormat:@"Send (%d)",self.selectedItems.count]];
            [self.deleteButton setTitle:[NSString stringWithFormat:@"Delete (%d)",self.selectedItems.count]];
            [self.sendButton setEnabled:YES];
            [self.deleteButton setEnabled:YES];
        }
        else{
            [self.sendButton setTitle:@"Send"];
            [self.deleteButton setTitle:@"Delete"];
            [self.sendButton setEnabled:NO];
            [self.deleteButton setEnabled:NO];
        }
    }

    
    else{
        
        [self imageDidSelectedWithIndex:(button.tag -1)];

        

    }
}
-(void)imageDidSelectedWithIndex:(int)selectedImage{
    NSString *path = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.items objectAtIndex:selectedImage]   ];
    
    //NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
    //UIImage *img =  [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:IMAGES],[self.items                                             objectAtIndex:button.tag-1]]];
    NSLog(@"image: %@",[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:IMAGES],[self.items objectAtIndex:selectedImage]]);
    UIImage *img = [[UIImage alloc]initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:IMAGES],[self.items objectAtIndex:selectedImage]]];
    NSLog(@"size: %f x %f",img.size.width,img.size.height);
    NSString *user = [[NSString alloc] initWithString:self.username];
    NSString *filename = [[NSString alloc] initWithString:[self.items objectAtIndex:selectedImage]];
    
    [self.tagViewController setImage:img];
    [self.tagViewController setUsername:user];
    [self.tagViewController.annotationView reset];
    [self.tagViewController.annotationView.objects setArray:objects];
    //[self.tagViewController.annotationView.objects release];
    //[self.tagViewController.annotationView setNumLabels:self.tagViewController.annotationView.objects.count];
    [self.tagViewController setFilename:filename];
    self.tagViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.tagViewController animated:YES];
    
    
}
-(IBAction)listSendAction:(id)sender{
    /*[self.usernameLabel setHidden:YES];
    [self.progressView setHidden:NO];
    [self.XButton setHidden:NO];*/
    [sendingView setHidden:NO];
    [self.tabBarController.tabBar setUserInteractionEnabled:NO];
    photosWithErrors = 0;
    [self.editButton setEnabled:NO];
                                
    [sendingView.activityIndicator startAnimating];
    [sendingView setTotal:self.selectedItemsSend.count];
    UIButton *button = (UIButton *)sender;
    [self.selectedItemsSend addObject:[self.items objectAtIndex:button.tag-10]];
    if (self.selectedItemsSend.count == 1) {
        [self sendPhoto];
    }
}

-(IBAction)deleteAction:(id)sender{
    NSString *str = nil;
    if (self.selectedItems.count == 1) {
        str = [[NSString alloc] initWithFormat:@"Delete Selected Photo"];
    }
    else{
         str = [[NSString alloc] initWithFormat:@"Delete %d Selected Photos",self.selectedItems.count];
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:str otherButtonTitles:nil, nil];
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    actionSheet.tag = 0;
    //[actionSheet showFromTabBar:self.tabBarController.tabBar];
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
}

-(IBAction)sendAction:(id)sender{
    [self.selectedItemsSend addObjectsFromArray:self.selectedItems];
    /*[self.usernameLabel setHidden:YES];
    [self.progressView setHidden:NO];
    [self.XButton setHidden:NO];*/
    [sendingView.activityIndicator startAnimating];

    [sendingView setHidden:NO];
    [self.tabBarController.tabBar setUserInteractionEnabled:NO];

    [self.editButton setEnabled:NO];
    [sendingView setTotal:self.selectedItemsSend.count];
    photosWithErrors = 0;
    [self sendPhoto];
    //[self performSelectorInBackground:@selector(sendPhoto) withObject:nil];
    [self.selectedItems removeAllObjects];
    [self editAction:self.editButton];
    
}
-(IBAction)listAction:(id)sender{
    UIButton *button = (UIButton *)sender;
    if (!button.isSelected) {
        self.tableViewGrid.hidden = YES;
        self.tableView.hidden = NO;
        [self.listButton setSelected:YES];
    }
    else {
        self.tableViewGrid.hidden = NO;
        self.tableView.hidden = YES;
        [self.listButton setSelected:NO];
        
    }
    [self reloadGallery];

    
}

-(IBAction)cancelAction:(id)sender{
    [serverConnection cancelRequestFor:0];

    [self.selectedItemsSend removeAllObjects];
    [self.usernameLabel setHidden:NO];

}
#pragma mark -
#pragma mark UIActionSheetDelegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag == 0) {
        if (buttonIndex==0) {
            
            [self.selectedItemsDelete addObjectsFromArray:self.selectedItems];
            
            [self deletePhotoAndAnnotation];
      
        }
        [self.selectedItems removeAllObjects];
        //

    }
   
    [self editAction:self.editButton];
    [self reloadGallery];

}
#pragma mark -
#pragma mark Deleting Methods
-(void)deletePhotoAndAnnotation{
    int index = 0;
    NSError *error = nil;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSFileManager *filemng = [NSFileManager defaultManager];
    if (![filemng removeItemAtPath:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.selectedItemsDelete objectAtIndex:index]] error:&error]) {
        [NSKeyedArchiver archiveRootObject:dict toFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:OBJECTS],[self.selectedItems objectAtIndex:index] ]];
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Error" message:@"It can not be removed." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        UIImage *thumim =  [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.selectedItemsDelete objectAtIndex:index]]];
        
        if (![filemng removeItemAtPath:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:IMAGES],[self.selectedItemsDelete objectAtIndex:index]] error:&error]) {
            NSData *thum = UIImageJPEGRepresentation(thumim, 0.75);
            [NSKeyedArchiver archiveRootObject:dict toFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:OBJECTS],[self.selectedItemsDelete objectAtIndex:index] ]];
            [filemng createFileAtPath:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.selectedItemsDelete objectAtIndex:index]] contents:thum attributes:nil];
            UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Error" message:@"It can not be removed." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else {
            
            if (![filemng removeItemAtPath:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:OBJECTS],[self.selectedItemsDelete objectAtIndex:index] ] error:&error]) {

                UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Error" message:@"It can not be removed." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
            }
            else{
                [filemng removeItemAtPath:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:OBJECTS],[[[self.selectedItemsDelete objectAtIndex:index] stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"]  ] error:&error];
            }
            [dict removeObjectForKey:[self.selectedItemsDelete objectAtIndex:index]];
        }
    }
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:YES];
    [self.selectedItemsDelete removeObjectAtIndex:index];
    if(self.selectedItemsDelete.count > 0){
        [self deletePhotoAndAnnotation];
    }
    [self reloadGallery];
}
#pragma mark -
#pragma mark Sending Methods
-(void)sendPhoto{
   /* ServerConnection * sConnection = [[ServerConnection alloc] init];
    sConnection.delegate = self;*/
    NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *num = [dict objectForKey:[self.selectedItemsSend objectAtIndex:0]];

    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:[self.selectedItemsSend objectAtIndex:0]]];
    double f =image.size.height/image.size.width;
    NSMutableArray *annotation = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.selectedItemsSend objectAtIndex:0] ] ];
    Box *box = nil;
    CGPoint point;

    if (annotation.count >0) {
        box = [annotation objectAtIndex:0];
        if (f>1) {
            //self.scrollView.frame.size.width-self.scrollView.frame.size.height /f)/2
            point = CGPointMake(image.size.height/([box bounds].x*f), image.size.height/[box bounds].y);
            
            
            
        }
        else {
            point = CGPointMake(image.size.width/([box bounds].x), image.size.width*f/([box bounds].y));
            
        }
        


    }
    
    if (num.intValue <0) {
        // Photo is not in the server
        [serverConnection sendPhoto:image filename:[self.selectedItemsSend objectAtIndex:0] path:[self.paths objectAtIndex:OBJECTS] withSize:point andAnnotation:annotation];
    }
    else{
        // Photo is in the server, overwrite the annotation
        [serverConnection updateAnnotationFrom:[self.selectedItemsSend objectAtIndex:0] withSize:point :annotation];
    }
    //[sConnection release];
    
}
#pragma mark -
#pragma mark ServerConnectionDelegate Methods
-(void)photoSentCorrectly:(NSString *)filename{
    [self.selectedItemsSend removeObject:filename];
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    if (objects != nil) {
        for (int i=0; i<objects.count; i++) {
            [[objects objectAtIndex:i] setSent:YES];
        }
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];

    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:0];
    [dict removeObjectForKey:filename];
    [dict setObject:newdictnum forKey:filename];
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    if (self.selectedItemsSend.count > 0) {
        [sendingView.progressView setProgress:0];
        [sendingView incrementNum];
        [self sendPhoto];
    }
    else{
        /*[self.usernameLabel setHidden:NO];
        [self.progressView setHidden:YES];
        [self.XButton setHidden:YES];
        [self.progressView setProgress:0];*/
        if (photosWithErrors >0) {
            if (photosWithErrors == 1) {
                [self errorWithTitle:@"An image could not be sent" andDescription:@"Please, try again."];
            }
            else{
                [self errorWithTitle:[NSString stringWithFormat:@"%d images could not be sent.",photosWithErrors] andDescription:@"Please, try again."];
            }

        }
        [sendingView reset];
        [sendingView setHidden:YES];
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];

        [self.editButton setEnabled:YES];
        [sendingView.activityIndicator stopAnimating];

    }
    [self reloadGallery];
}
-(void)sendingProgress:(float)prog{
    [sendingView.progressView setProgress:prog];

}
-(void)sendPhotoError{
    photosWithErrors++;
    [self.selectedItemsSend removeObjectAtIndex:0];
    if (self.selectedItemsSend.count > 0) {
        [sendingView.progressView setProgress:0];
        [sendingView incrementNum];
        [self sendPhoto];
    }
    else if (photosWithErrors > 0 ){
        if (photosWithErrors == 1) {
            [self errorWithTitle:@"An image could not be sent" andDescription:@"Please, try again."];
        }
        else{
            [self errorWithTitle:[NSString stringWithFormat:@"%d images could not be sent.",photosWithErrors] andDescription:@"Please, try again."];
        }
        [sendingView reset];
        [sendingView setHidden:YES];
        [sendingView.activityIndicator stopAnimating];
        
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];
        [self.editButton setEnabled:YES];
    }
    
     /*[sendingView reset];
    
     [sendingView setHidden:YES];
     [self.editButton setEnabled:YES];
     [sendingView.activityIndicator stopAnimating];
     [self.selectedItemsSend removeAllObjects];*/

}
                 
-(void)photoNotOnServer:(NSString *)filename{
    //[self.selectedItemsSend removeObject:filename];
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    if (objects != nil) {
        for (int i=0; i<objects.count; i++) {
            [[objects objectAtIndex:i] setSent:NO];
        }
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
        
    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:(-objects.count-1)];
    [dict removeObjectForKey:filename];
    [dict setObject:newdictnum forKey:filename];
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    if (self.selectedItemsSend.count > 0) {
        [self sendPhoto];
    }
    else{
        [self.usernameLabel setHidden:NO];

        [sendingView reset];
        [sendingView setHidden:YES];
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];

        [self.editButton setEnabled:YES];
        [sendingView.activityIndicator stopAnimating];

    }
    [self reloadGallery];
}



         

#pragma mark -
#pragma mark TableView Delegate&Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    NSInteger ret = 0;
    if (tableView.tag == 0 && (self.items.count>0)) {
        ret = 1;
    }
    else if (tableView.tag == 1){
        ret = self.items.count;
    }
    return ret;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 1) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [self.selectedItemsDelete addObject:[self.items objectAtIndex:indexPath.row]];
            if (self.selectedItemsDelete.count == 1) {
                [self deletePhotoAndAnnotation];

            }
           // [self reloadGallery];
            
            /*UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
             UIButton *button =  (UIButton *)[cell.contentView viewWithTag:22];
             button.hidden = NO;*/
            
            
        }

    }
    
}
- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag == 1) {
        UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
        UIButton *button =  (UIButton *)[cell.contentView viewWithTag:indexPath.row+10];
        button.hidden = YES;
    }
  
}
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag == 1) {
        UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
        UIButton *button =  (UIButton *)[cell.contentView viewWithTag:indexPath.row+10];
        if (![button.titleLabel.text isEqualToString:@""]) {
            button.hidden = NO;
        }

    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
    UITableViewCell *cell = nil;
     NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    if (tableView.tag == 0) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        NSFileManager * filemng = [NSFileManager defaultManager];
        [self setItems:[filemng contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.paths objectAtIndex:THUMB]] error:NULL]];
        for(int i = 0; i < self.items.count; i++) {
            @autoreleasepool {
                NSNumber *num = [dict objectForKey:[self.items objectAtIndex:i]];
                
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0.0375*self.view.frame.size.width,0.4125*self.view.frame.size.width, 0.4125*self.view.frame.size.width)];
                imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:i]]];
                UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width)];
                //[ imview setBackgroundColor:[UIColor colorWithRed:(237.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0] ];
                
                [imview addSubview:imageView];
                UIGraphicsBeginImageContext(CGSizeMake(0.45*self.view.frame.size.width,0.45*self.view.frame.size.width));
                
                [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
                UIGraphicsBeginImageContext(CGSizeMake(0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width));

                imview.alpha = 0.65;
                [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];

                UIImage *image2 = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();

                UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.tag = i+1;
                // [button setImage:image forState:UIControlStateNormal];
                //button.frame = CGRectMake(width/80+width/4*(i%4), width/80+width/4*(floor((i/4))), 15*width/64, 15*width/64);
                // button.frame = CGRectMake(width/4*(i%4), width/80+width/4*(floor((i/4))), width/4, width/4);
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {

                    button.frame = CGRectMake(0.05*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.225*self.view.frame.size.width, 0.225*self.view.frame.size.width);
                }
                else{
                    button.frame = CGRectMake(0.07*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.2*self.view.frame.size.width, 0.2*self.view.frame.size.width);

                }
                [button addTarget:self
                           action:@selector(buttonClicked:)
                 forControlEvents:UIControlEventTouchUpInside];
                [button setImage:image forState:UIControlStateNormal];
                [button setImage:[self addBorderTo:image2] forState:UIControlStateSelected];
                [button addSubview:[self correctAccessoryAtIndex:i withNum:num withSize:button.frame.size]];
                /*[button.layer setShadowColor:[UIColor blackColor].CGColor];
                [button.layer setShadowOffset:CGSizeMake(0, 1)];
                [button.layer setShadowOpacity:0.9];
                [button.layer setShadowRadius:3.0];
                [button setClipsToBounds:NO];*/
               
                [cell addSubview:button];
            }
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

        
    }
    else if (tableView.tag == 1) {
       
        NSNumber *num = [dict objectForKey:[self.items objectAtIndex:indexPath.row]];
        
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        UIButton  *button = nil;
        if (num.intValue < 0) {
            button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [button setTitle:@"Send" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithRed:(237.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0] forState:UIControlStateNormal];
            
        }
        else if (num.intValue == 0){
            button = [UIButton buttonWithType:UIButtonTypeCustom];
            
            [button setHidden:YES];
        }
        else{
            button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            
            [button setTitle:@"Update" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithRed:(237.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0] forState:UIControlStateNormal];
            
            
        }
       // [cell setEditing:YES animated:YES];
        [button setFrame:CGRectMake(self.view.frame.size.width-0.40625*self.view.frame.size.width, 0.0625*self.view.frame.size.width, 0.234375*self.view.frame.size.width, 0.109375*self.view.frame.size.width)];
        [button setTag:indexPath.row+10];
        [button addTarget:self action:@selector(listSendAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:button];
        if (self.editButton.title == @"Done") {
            [button setHidden:YES];

        }
        // Configure the cell...
        /*[sendTable setFrame:CGRectMake(cell.frame.size.width-40-cell.frame.size.height, cell.frame.size.height/3, cell.frame.size.height, cell.frame.size.height/3)];*/
        /* button =  (UIButton *)[cell.contentView viewWithTag:indexPath.row+10];
         if (button == nil) {
         button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
         [button setTitle:@"Send" forState:UIControlStateNormal];
         [cell setEditing:YES animated:YES];
         [button setFrame:CGRectMake(self.view.frame.size.width-40-75, 20, 75, 35)];
         [button setTag:indexPath.row+10];
         [button addTarget:self action:@selector(listSendAction:) forControlEvents:UIControlEventTouchUpInside];
         [cell.contentView addSubview:button];
         
         
         }
         [button setTag:indexPath.row + 10];*/
        
        
        NSString *path = [[NSString alloc]initWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:indexPath.row] ];
        NSMutableArray *annotation = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.items objectAtIndex:indexPath.row] ] ];
        UIImage *newimage = [[UIImage alloc]initWithContentsOfFile:[[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:[self.items objectAtIndex:indexPath.row]] ];
        [cell.detailTextLabel setNumberOfLines:2];
        NSString *detailText = [[NSString alloc]initWithFormat:@"%d objects\n%d x %d",annotation.count,(int)newimage.size.width,(int)newimage.size.height];
        //    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, 90, 90)];
        //    imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:indexPath.row]]];
        //    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
                           
        //
        //    [imageView.layer  renderInContext:UIGraphicsGetCurrentContext()];
        //    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        //    UIGraphicsEndImageContext();
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0375*self.view.frame.size.width, 0.0375*self.view.frame.size.width, 0.425*self.view.frame.size.width, 0.425*self.view.frame.size.width)];
        imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:indexPath.row]]];
        UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.5*self.view.frame.size.width,  0.5*self.view.frame.size.width)];
        [imview addSubview:imageView];
        UIGraphicsBeginImageContext(CGSizeMake( 0.5*self.view.frame.size.width,  0.5*self.view.frame.size.width));
        
        [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView setImage:image];
        // [cell.imageView setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:indexPath.row]]]];
        [cell.imageView addSubview:[self correctAccessoryAtIndex:indexPath.row withNum:num withSize:CGSizeMake(tableView.rowHeight , tableView.rowHeight)]];
        [cell.detailTextLabel setText:detailText];
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
        NSString *date = [[NSString alloc]initWithFormat:@"%@-%@-%@",[[self.items objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(4, 2)],[[self.items objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(6, 2)],[[self.items objectAtIndex:indexPath.row] substringToIndex:4] ];
        
        [cell.textLabel setText:date];
        /*[cell.imageView.layer setShadowColor:[UIColor blackColor].CGColor];
        [cell.imageView.layer setShadowOffset:CGSizeMake(0, 1)];
        [cell.imageView.layer setShadowOpacity:0.9];
        [cell.imageView.layer setShadowRadius:3.0];
        [cell.imageView.layer setCornerRadius:6.0];
        [cell.imageView setClipsToBounds:NO];*/
        // [img release];
    }
   

    return cell;
    
    // Configure the cell...
    
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 0) {
        return NO;
    }
    else{
        UIButton *button =  (UIButton *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:indexPath.row+10];
        if (([button.titleLabel.text length]>0) && (![tableView isEditing])) {
            button.hidden = NO;

        }
        else{
            button.hidden = YES;

        }
        return YES;
        
        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1) {
        [self imageDidSelectedWithIndex:indexPath.row];

    }
    
    
    
}
#pragma mark -
#pragma mark SendingView
-(void)cancel{
    [serverConnection cancelRequestFor:0];
    [self.selectedItemsSend removeAllObjects];
    [sendingView reset];
    [sendingView.progressView setProgress:0];
    [sendingView setHidden:YES];
    [self.tabBarController.tabBar setUserInteractionEnabled:YES];

    [self.editButton setEnabled:YES];
    [sendingView.activityIndicator stopAnimating];

    
}
#pragma mark -
#pragma mark Memory Managemente Methods

- (void)didReceiveMemoryWarning
{

    [super didReceiveMemoryWarning];
}

-(void)dealloc{
    self.editButton;
    self.bottomToolbar;
    self.deleteButton;
    self.sendButton;
    self.usernameLabel;

    self.profilePicture;
    self.listButton;
    self.paths;
    self.items;
    self.selectedItems;
    
    self.selectedItemsSend;
    self.selectedItemsDelete;
    self.tagViewController;
    self.tableView;
    self.tableViewGrid;
    


}

@end
