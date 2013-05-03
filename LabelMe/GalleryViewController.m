//
//  GalleryViewController.m
//  LabelMe
//
//  Created by Dolores on 28/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CALayer.h>
#include <stdlib.h>

#import "GalleryViewController.h"
#import "Constants.h"
#import "Box.h"
#import "ServerConnection.h"
#import "CustomBadge.h"
#import "UIImage+Resize.h"
#import "NSObject+ShowAlert.h"
#import "NSObject+Folders.h"
#import "Box.h"



@interface GalleryViewController()

//Return the list of files of path ordered by modification date
- (NSArray *) getOrderedListOfFilesForPath:(NSString *)path;


//arrays to store information about downloaded images from server
@property (nonatomic, strong) NSMutableArray *downloadedThumbnails;
@property (nonatomic, strong) NSMutableArray *downloadedAnnotations;
@property (nonatomic, strong) NSMutableArray *downloadedImageUrls;
@property (nonatomic, strong) NSMutableArray *downloadedImageNames;
@property (nonatomic, strong) NSMutableDictionary *downloadedLabelsMap; //label -> array with indexes 

@end





@implementation GalleryViewController

@synthesize editButton = _editButton;
@synthesize bottomToolbar = _bottomToolbar;
@synthesize deleteButton = _deleteButton;
@synthesize sendButton = _sendButton;
@synthesize usernameLabel = _usernameLabel;
@synthesize profilePicture = _profilePicture;

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



#pragma mark
#pragma mark - setters and getters



#pragma mark -
#pragma mark lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //objects initialization
        self.items = [[NSArray alloc] init];
        self.selectedItems = [[NSMutableArray alloc]init];
        self.selectedItemsSend = [[NSMutableArray alloc]init];
        self.selectedItemsDelete = [[NSMutableArray alloc]init];
        self.username = [[NSString alloc] init];
        serverConnection = [[ServerConnection alloc] init];
        
        //tab bar
        self.tabBarItem= [[UITabBarItem alloc]initWithTitle:@"Label" image:nil tag:0];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"home.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"homeActive.png"]];
        
        //buttons
        self.sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendAction:)];
        self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteAction:)];
        self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editAction:)];
        
        serverConnection.delegate = self;
        self.modalTVC = [[ModalTVC alloc] initWithNibName:@"ModalTVC" bundle:nil];
        self.cameraVC = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
        self.cameraVC.delegate = self;
        
        //GPS settings
        self.locationMng = [[CLLocationManager alloc] init];
        self.locationMng.desiredAccuracy = kCLLocationAccuracyKilometer;

    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.usernameLabel.text = self.username;
    [self.usernameLabel setTextColor:[UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0]];
    self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];
    photosWithErrors = 0;

    
    //titleView: LabelMe Logo and title images
    UIImage *titleImage = [UIImage imageNamed:@"logo-title.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    [titleView setImage:titleImage];
    [self.navigationItem setTitleView:titleView];
    UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"];
    
    //profile picture
    self.profilePicture = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, view1.frame.size.width, view1.frame.size.height)];
    self.profilePicture.layer.masksToBounds = YES;
    self.profilePicture.layer.cornerRadius = 6.0;
    [self.profilePicture setContentMode:UIViewContentModeScaleAspectFit];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self.paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]])
        [self.profilePicture setImage:[UIImage imageWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]] ];
    else [self.profilePicture setImage:[UIImage imageNamed:@"silueta.png"]];
    
    
    //buttons
    [self.editButton setStyle:UIBarButtonItemStyleBordered];
    UIBarButtonItem *plusButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addImage:)];
    self.navigationItem.leftBarButtonItem = plusButton;
    self.navigationItem.rightBarButtonItem = self.editButton;
    [self.deleteButton setTintColor:[UIColor redColor]];
    [self.deleteButton setWidth:self.view.frame.size.width/2 - 11];
    [self.sendButton setWidth:self.view.frame.size.width/2 - 11];
    [self.deleteButton setEnabled:NO];
    [self.sendButton setEnabled:NO];
    
    //navigation and tool bar
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.navigationController.navigationBar setBackgroundImage:barImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];

    //device selection for tagVC
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([UIScreen mainScreen].bounds.size.height == 568)
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone5" bundle:nil];
        else if ([UIScreen mainScreen].bounds.size.height == 480)
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone" bundle:nil];
    }else self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPad" bundle:nil];
    
    [self.listButton setImage:[UIImage imageNamed:@"listC.png"] forState:UIControlStateNormal];
    [self.listButton setImage:[UIImage imageNamed:@"gridC.png"] forState:UIControlStateSelected];
    
    //table views
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:nil];
    self.tableView.hidden = YES;
    self.tableView.rowHeight = self.view.frame.size.width/4;
    self.tableView.tag = 1;
    
    self.tableViewGrid.backgroundColor = [UIColor clearColor];
    [self.tableViewGrid setBackgroundView:nil];
    self.tableViewGrid.tag = 0;
    
    //create a footer view on the bottom of the tableview
    self.tableView.tableFooterView = [self footerViewCreationAtHeight:0];
    self.tableViewGrid.tableFooterView = [self footerViewCreationAtHeight:0];
    
    //no images view
    noImages = [[UILabel alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x+0.03125*self.view.frame.size.width, self.tableView.frame.origin.y+0.03125*self.view.frame.size.width, self.tableView.frame.size.width-0.0625*self.view.frame.size.width, self.tableView.frame.size.height-0.0625*self.view.frame.size.width)];
    [noImages setBackgroundColor:[UIColor whiteColor]];
    noImages.layer.masksToBounds = YES;
    noImages.layer.cornerRadius = 10.0;
    noImages.layer.shadowColor = [UIColor grayColor].CGColor;
    noImages.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    noImages.shadowColor = [UIColor grayColor];
    [noImages setNumberOfLines:2];
    noImages.shadowOffset = CGSizeMake(0.0, 1.0);
    noImages.text = @"You do not have images, \nstart taking pics and labeling or download from web!";
    [noImages setTextAlignment:NSTextAlignmentCenter];
    [noImages addSubview:[self footerViewCreationAtHeight:190]];
    [noImages setUserInteractionEnabled:YES];
    
    //sending view
    sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    [sendingView setHidden:YES];
    sendingView.delegate = self;
    sendingView.label.text = @"Uploading image to server";

    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.tableViewGrid];
    [self.view addSubview:noImages];
    [self.view addSubview:sendingView];

    [view1.layer setShadowColor:[UIColor blackColor].CGColor];
    [view1.layer setShadowOffset:CGSizeMake(0, 1)];
    [view1.layer setShadowOpacity:0.9];
    [view1.layer setShadowRadius:3.0];
    [view1.layer setCornerRadius:6.0];
    [view1 addSubview:self.profilePicture];
    [view1 setClipsToBounds:NO];
    

    
    [self reloadGallery];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //upload profile picture
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[self.paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]])
        [self.profilePicture setImage:[UIImage imageWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]] ];
    else [self.profilePicture setImage:[UIImage imageNamed:@"silueta.png"]];
    
    [self reloadGallery];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.editButton.title isEqual: @"Cancel"]) {
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
    }
}


#pragma mark -
#pragma mark Gallery Management

-(void) reloadGallery
{
    
    //get sorted files by date of modification of the image
    self.items = [self getOrderedListOfFilesForPath:[self.paths objectAtIndex:IMAGES]];
    
    if(self.items.count == 0) {
        noImages.hidden = NO;
        self.tableView.hidden = YES;
        self.tableViewGrid.hidden = YES;
    }
    else noImages.hidden = YES;
    
    [self.tableViewGrid setRowHeight:(0.225*self.view.frame.size.width*ceil((float)self.items.count/4) + 0.0375*self.view.frame.size.width)];
    [self.tableView reloadData];
    [self.tableViewGrid reloadData];
}



-(UIView *)correctAccessoryAtIndex:(int)i withNum:(NSNumber *)num withSize:(CGSize)size
{
    UIView *ret = nil;
    CGSize size2 = size;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        size2 = CGSizeMake(80, 80);

    if (num.intValue < 0) {
        NSString *numBadge = [[NSString alloc] initWithFormat:@"%d",abs(num.intValue+1)];
        CustomBadge *accessory = [CustomBadge customBadgeWithString:numBadge withStringColor:[UIColor whiteColor] withInsetColor:[UIColor redColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor] withScale:1.0 withShining:YES];
        [accessory setFrame:CGRectMake(size.width- 0.30*size2.width, 0, 0.30*size2.width, 0.30*size2.width)];
        ret = accessory;
        
    }else if (num.intValue == 0){
        UIImageView *accessory =  [[UIImageView alloc] initWithFrame:CGRectMake(size.width- 0.25*size2.width, 0, 0.25*size2.width, 0.25*size2.width)];
        accessory.image = [UIImage imageNamed:@"tick.png"];
        ret = accessory;
        
    }else{
        CustomBadge *accessory = [CustomBadge customBadgeWithString:num.stringValue withStringColor:[UIColor whiteColor] withInsetColor:[UIColor orangeColor] withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor] withScale:1.0 withShining:YES];
        [accessory setFrame:CGRectMake(size.width- 0.30*size2.width, 0, 0.30*size2.width, 0.30*size2.width)];
        ret = accessory;
    }
    
    return  ret;
}


- (UIImage *) addBorderTo:(UIImage *)image
{
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
    
	return newImage;
}


#pragma mark -
#pragma mark IBActions

-(IBAction)editAction:(id)sender
{
    //grid
    if (!self.listButton.isSelected) {
        if ([self.editButton.title isEqual: @"Edit"]) {
            [self.listButton setHidden:YES];
            [self.editButton setTitle:@"Cancel"];
            [self.navigationController setToolbarHidden:NO];
            NSArray *toolbarItems = [[NSArray alloc] initWithObjects:self.sendButton,self.deleteButton, nil];
            [self.navigationController.toolbar setItems:toolbarItems];
            [self.tableViewGrid setFrame:CGRectMake(self.tableViewGrid.frame.origin.x, self.tableViewGrid.frame.origin.y, self.tableViewGrid.frame.size.width, self.tableViewGrid.frame.size.height - self.navigationController.toolbar.frame.size.height)];
            [self.editButton setStyle:UIBarButtonSystemItemCancel];
            
        }else{
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
        
    //list
    }else{
        if ([self.editButton.title isEqual: @"Edit"]) {
            [self.tableView setEditing:YES animated:YES];
            [self.listButton setHidden:YES];
            [self.editButton setTitle:@"Done"];
            [self.editButton setStyle:UIBarButtonSystemItemDone];

        }else{

            [self.tableView setEditing:NO animated:YES];
            [self.listButton setHidden:NO];
            [self.editButton setTitle:@"Edit"];
            [self.editButton setStyle:UIBarButtonItemStyleBordered];
            
        }
    }
    
}

-(IBAction)addImage:(id)sender
{
    self.cameraVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.cameraVC animated:YES];

}

-(IBAction)buttonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    if ([self.editButton.title isEqual: @"Cancel"]) {
        if ([self.selectedItems containsObject:[self.items objectAtIndex:abs(button.tag)-1]]) {
            [self.selectedItems removeObject:[self.items objectAtIndex:abs(button.tag)-1]];
            [button setSelected:NO];
            
        }else{
            [self.selectedItems addObject:[self.items objectAtIndex:abs(button.tag)-1]];
            [button setSelected:YES];
        }
        
        if (self.selectedItems.count > 0) {
            [self.sendButton setTitle:[NSString stringWithFormat:@"Send (%d)",self.selectedItems.count]];
            [self.deleteButton setTitle:[NSString stringWithFormat:@"Delete (%d)",self.selectedItems.count]];
            [self.sendButton setEnabled:YES];
            [self.deleteButton setEnabled:YES];
        }else{
            [self.sendButton setTitle:@"Send"];
            [self.deleteButton setTitle:@"Delete"];
            [self.sendButton setEnabled:NO];
            [self.deleteButton setEnabled:NO];
        }
    }

    
    else [self imageDidSelectedWithIndex:(button.tag-1)];
    
}


-(void)imageDidSelectedWithIndex:(int)selectedImage
{
    NSString *path = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.items objectAtIndex:selectedImage]];
    NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];    
    
    NSLog(@"image: %@",[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:IMAGES],[self.items objectAtIndex:selectedImage]]);
    UIImage *img = [[UIImage alloc]initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:IMAGES],[self.items objectAtIndex:selectedImage]]];
    NSLog(@"size: %f x %f",img.size.width,img.size.height);
    NSString *user = [[NSString alloc] initWithString:self.username];
    NSString *filename = [[NSString alloc] initWithString:[self.items objectAtIndex:selectedImage]];
    [self.tagViewController setImage:img];
    [self.tagViewController setUsername:user];
    [self.tagViewController.annotationView reset];
    [self.tagViewController.annotationView.objects setArray:objects];
    [self.tagViewController setFilename:filename];
    self.tagViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.tagViewController animated:YES];
    
}


-(IBAction)listSendAction:(id)sender
{
    sendingView.total = self.selectedItemsSend.count;
    [sendingView setHidden:NO];
    [sendingView.activityIndicator startAnimating];
    
    [self.tabBarController.tabBar setUserInteractionEnabled:NO];
    photosWithErrors = 0;
    [self.editButton setEnabled:NO];
    UIButton *button = (UIButton *)sender;
    [self.selectedItemsSend addObject:[self.items objectAtIndex:button.tag-10]];
    if (self.selectedItemsSend.count == 1) {
        [self sendPhoto];
    }
}

-(IBAction)deleteAction:(id)sender
{
    NSString *str = nil;
    if (self.selectedItems.count == 1)
        str = @"Delete Selected Photo";
    else str = [[NSString alloc] initWithFormat:@"Delete %d Selected Photos",self.selectedItems.count];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:str otherButtonTitles:nil, nil];
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    actionSheet.tag = 0;
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
}

-(IBAction)sendAction:(id)sender
{
    [self.selectedItemsSend addObjectsFromArray:self.selectedItems];
    
    [sendingView.activityIndicator startAnimating];
    [sendingView setHidden:NO];
    
    [self.tabBarController.tabBar setUserInteractionEnabled:NO];

    [self.editButton setEnabled:NO];
    [sendingView setTotal:self.selectedItemsSend.count];
    photosWithErrors = 0;
    [self sendPhoto];
    [self.selectedItems removeAllObjects];
    [self editAction:self.editButton];
    
}


-(IBAction)listAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    if (!button.isSelected) {
        self.tableViewGrid.hidden = YES;
        self.tableView.hidden = NO;
        [self.listButton setSelected:YES];
        
    }else {
        self.tableViewGrid.hidden = NO;
        self.tableView.hidden = YES;
        [self.listButton setSelected:NO];
    }
    
    [self reloadGallery];
}

-(IBAction)cancelAction:(id)sender
{
    [serverConnection cancelRequestFor:0];

    [self.selectedItemsSend removeAllObjects];
    [self.usernameLabel setHidden:NO];
}


-(IBAction) moreImagesAction:(id)sender
{
    
    //start spin indicator for the activity
    UIButton *button = (UIButton *)sender;
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    for(id subview in [button subviews])
        if([subview isKindOfClass:[UIActivityIndicatorView class]])
            indicator = (UIActivityIndicatorView *)subview;
    [indicator startAnimating];

    
    NSString *buttonTitle = button.titleLabel.text;

    NSString *query = @"http://labelme2.csail.mit.edu/developers/mingot/LabelMe3.0/iphoneAppTools/download.php?username=mingot";
    NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:query] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error] : nil;
    if (error) NSLog(@"[%@ %@] JSON error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);

    self.downloadedThumbnails = [[NSMutableArray alloc] init];
    self.downloadedAnnotations = [[NSMutableArray alloc] init];
    self.downloadedImageUrls = [[NSMutableArray alloc] init];
    self.downloadedImageNames = [[NSMutableArray alloc] init];
    self.downloadedLabelsMap = [[NSMutableDictionary alloc] init];

    NSArray *colors = [[NSArray alloc] initWithObjects:[UIColor blueColor],[UIColor cyanColor],[UIColor greenColor],[UIColor magentaColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor purpleColor],[UIColor brownColor], nil];

    //select NUM images not currently present in iphone
    for (NSDictionary *element in results) {
        
        //get the name of the image
        NSString *imageName = [element objectForKey:@"name"];

        
        if([self.items indexOfObject:imageName] == NSNotFound){
            
            //save the name of the image
            [self.downloadedImageNames addObject:imageName];
            NSLog(@"found image %@ and inserting", imageName);
           
            //get and save thumb
            NSString *thumbUrl = [element objectForKey:@"thumb"];
            UIImage *thumbImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:thumbUrl]]];
            NSLog(@"thumb %@", thumbImage);
            if(thumbImage!=nil) [self.downloadedThumbnails addObject:thumbImage];
            else [self.downloadedThumbnails addObject:[UIImage imageNamed:@"image_not_found.png"]];
            
            //get and save images urls
            NSString *imageUrl = [element objectForKey:@"image"];
            NSLog(@"image url %@", imageUrl);
            [self.downloadedImageUrls addObject:imageUrl];

            
            //get and save annotations
            NSMutableArray *boundingBoxes = [[NSMutableArray alloc] init];
            NSDictionary *annotation = (NSDictionary *) [element objectForKey:@"annotation"];
            NSDictionary *imageSize = (NSDictionary *) [annotation objectForKey:@"imagesize"];
            
            
            id objects = [annotation objectForKey:@"object"];
            NSArray *boxes;
            if([objects isKindOfClass:[NSArray class]]) boxes = (NSArray *) objects;
            else boxes = [[NSArray alloc] initWithObjects:(NSDictionary *)objects, nil];
            
            for(NSDictionary *box in boxes){
                
                //label: insert into the map to download specific images for a given label
                NSString *label = [(NSString *) [box objectForKey:@"name"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                NSMutableArray *imageIndexes = [self.downloadedLabelsMap objectForKey:label];
                if(imageIndexes==nil){
                    imageIndexes = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithInt:self.downloadedImageNames.count-1], nil];
                    [self.downloadedLabelsMap setObject:imageIndexes forKey:label];
                
                }else [imageIndexes addObject:[NSNumber numberWithInt:self.downloadedImageNames.count-1]];
                
                
                NSDictionary *polygon = (NSDictionary *)[box objectForKey:@"polygon"];
                NSArray *points = (NSArray *)[polygon objectForKey:@"pt"];
                
                CGFloat xmin=100000, xmax=0, ymin=100000, ymax=0;
                for(NSDictionary *point in points){
                    int x = [[(NSString *)[point objectForKey:@"x"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] floatValue];
                    int y = [[(NSString *)[point objectForKey:@"y"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] floatValue];
                    xmin = x<xmin ? x:xmin;
                    xmax = x>xmax ? x:xmax;
                    ymin = y<ymin ? y:ymin;
                    ymax = y>ymax ? y:ymax;
                }
                
                //box construction
                Box *box = [[Box alloc] initWithPoints:CGPointMake(xmin*1.0, ymin*1.0) :CGPointMake(xmax*1.0, ymax*1.0)];
                box.label = label;
                box.sent = YES;
                box.color = [colors objectAtIndex:arc4random() % colors.count];  //choose random color
                box->UPPERBOUND = 0;
                box->LOWERBOUND = [[(NSString *)[imageSize objectForKey:@"nrows"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] intValue]*1.0;
                box->LEFTBOUND = 0;
                box->RIGHTBOUND = [[(NSString *)[imageSize objectForKey:@"ncols"] stringByReplacingOccurrencesOfString:@"\n" withString:@""] intValue]*1.0;
                box.downloadDate = [NSDate date];
                
                [boundingBoxes addObject:box];
                
                //NSLog(@"POINTS: (%f,%f), (%f,%f)", box.upperLeft.x,box.upperLeft.y, box.lowerRight.x, box.lowerRight.y);
                //NSLog(@"BOUNDS: %f, %f",box->LOWERBOUND, box->RIGHTBOUND);
                
            }
            
            //save the dictionary
            [self.downloadedAnnotations addObject:boundingBoxes];
        }
        
    }
    
    [indicator stopAnimating];
    
    //present the modal depending on the sender button: show images or labels
    if(self.downloadedThumbnails.count>0){
        if([buttonTitle isEqualToString:@"Server Images"]){
            self.modalTVC = [[ModalTVC alloc] init];
            self.modalTVC.showCancelButton = YES;
            self.modalTVC.delegate = self;
            self.modalTVC.modalTitle = @"Choose Images";
            self.modalTVC.data = self.downloadedThumbnails;
            [self.modalTVC.view setNeedsDisplay];
            [self presentModalViewController:self.modalTVC animated:YES];
        }else if([buttonTitle isEqualToString:@"Server Labels"]){
            
            //get the labels
            NSMutableArray *labels = [[NSMutableArray alloc] init];
            for(NSString *key in self.downloadedLabelsMap){
                NSArray *indexes = [self.downloadedLabelsMap objectForKey:key];
                [labels addObject:[NSString stringWithFormat:@"%@ (%d)",key,indexes.count]];
            }
            self.modalTVC = [[ModalTVC alloc] init];
            self.modalTVC.showCancelButton = YES;
            self.modalTVC.delegate = self;
            self.modalTVC.modalTitle = @"Choose Labels";
            self.modalTVC.multipleChoice = NO;
            self.modalTVC.data = [NSArray arrayWithArray:labels];
            [self.modalTVC.view setNeedsDisplay];
            [self presentModalViewController:self.modalTVC animated:YES];
        }
    }else{
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Empty"
                                                             message:@"You have all the images"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [errorAlert show];
    }

}


#pragma mark -
#pragma mark UIActionSheetDelegate Methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0){
        if (buttonIndex==0) {
            [self.selectedItemsDelete addObjectsFromArray:self.selectedItems];
            [self deletePhotoAndAnnotation];
        }
        [self.selectedItems removeAllObjects];
    }
   
    [self editAction:self.editButton];
    [self reloadGallery];
}



#pragma mark -
#pragma mark Deleting Methods

-(void)deletePhotoAndAnnotation
{
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

-(void)sendPhoto
{
    NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *num = [dict objectForKey:[self.selectedItemsSend objectAtIndex:0]];

    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:[self.selectedItemsSend objectAtIndex:0]]];
    
    NSMutableArray *annotation = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.selectedItemsSend objectAtIndex:0] ] ];
    Box *box = nil;
    CGPoint point;

    if (annotation.count >0) {
        double f =image.size.height/image.size.width;
        box = [annotation objectAtIndex:0];
        point = f>1 ? CGPointMake(image.size.height/([box bounds].x*f), image.size.height/[box bounds].y) : CGPointMake(image.size.width/([box bounds].x), image.size.width*f/([box bounds].y));
    }
    
    // Photo is not in the server
    if (num.intValue <0)
        [serverConnection sendPhoto:image filename:[self.selectedItemsSend objectAtIndex:0] path:[self.paths objectAtIndex:OBJECTS] withSize:point andAnnotation:annotation];
    
    // Photo is in the server, overwrite the annotation
    else [serverConnection updateAnnotationFrom:[self.selectedItemsSend objectAtIndex:0] withSize:point :annotation];
    
}

#pragma mark
#pragma mark - CameraVC Delegate

-(void) addImageCaptured:(UIImage *)image
{
    dispatch_queue_t savingQueue = dispatch_queue_create("saving_image", 0);
    dispatch_async(savingQueue, ^{
        NSLog(@"adding image to gallery");
        
        NSDictionary *userDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[self.userPaths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
        
        [self.locationMng startUpdatingLocation];
        TagViewController *tagViewController = [[TagViewController alloc] init];
        tagViewController.username = self.username;
        
        //get the new size of the image according to the defined resolution and save image
        CGSize newSize = image.size;
        float resolution = [[userDictionary objectForKey:@"resolution"] floatValue];
        float max = newSize.width > newSize.height ? newSize.width : newSize.height;
        if ((resolution != 0.0) && (resolution < max))
            newSize = image.size.height > image.size.width ? CGSizeMake(resolution*0.75, resolution) : CGSizeMake(resolution, resolution*0.75);
        NSLog(@"New size for the image %f %f", newSize.height, newSize.width);
        
        //save image into library if option enabled in settings
        if ([[userDictionary objectForKey:@"cameraroll"] boolValue]) UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        //save location information
        NSString *location = @"";
        location = [[self.locationMng.location.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
        [location writeToFile:[[self.userPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[[tagViewController.filename stringByDeletingPathExtension] stringByAppendingString:@".txt"]] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
        [self.locationMng stopUpdatingLocation];
        
        [tagViewController saveImage:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self reloadGallery];
            self.tableViewGrid.hidden = NO;
        });
    });
    dispatch_release(savingQueue);
}


#pragma mark -
#pragma mark ServerConnectionDelegate Methods

-(void)photoSentCorrectly:(NSString *)filename
{
    [self.selectedItemsSend removeObject:filename];
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    if (objects != nil) {
        for (int i=0; i<objects.count; i++) 
            [[objects objectAtIndex:i] setSent:YES];
        
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


-(void)sendingProgress:(float)prog
{
    [sendingView.progressView setProgress:prog];
}


-(void)sendPhotoError
{
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

}
                 
-(void)photoNotOnServer:(NSString *)filename{
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


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = 0;
    
    if (tableView.tag == 0 && (self.items.count>0))
        ret = 1;
    else if (tableView.tag == 1)
        ret = self.items.count;
    
    return ret;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1)
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [self.selectedItemsDelete addObject:[self.items objectAtIndex:indexPath.row]];
            if (self.selectedItemsDelete.count == 1)
                [self deletePhotoAndAnnotation];

        }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1) {
        UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
        UIButton *button =  (UIButton *)[cell.contentView viewWithTag:indexPath.row+10];
        button.hidden = YES;
    }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1) {
        UITableViewCell *cell =  [tableView cellForRowAtIndexPath:indexPath];
        UIButton *button =  (UIButton *)[cell.contentView viewWithTag:indexPath.row+10];
        if (![button.titleLabel.text isEqualToString:@""])
            button.hidden = NO;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  
    UITableViewCell *cell = nil;
    NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    
    //grid
    if (tableView.tag == 0) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        for(int i = 0; i < self.items.count; i++) {
            @autoreleasepool {
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0.0375*self.view.frame.size.width,0.4125*self.view.frame.size.width, 0.4125*self.view.frame.size.width)];
                imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:i]]];
                UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width)];

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

                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                    button.frame = CGRectMake(0.05*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.225*self.view.frame.size.width, 0.225*self.view.frame.size.width);
                else button.frame = CGRectMake(0.07*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.2*self.view.frame.size.width, 0.2*self.view.frame.size.width);


                [button addTarget:self
                           action:@selector(buttonClicked:)
                 forControlEvents:UIControlEventTouchUpInside];
                [button setImage:image forState:UIControlStateNormal];
                [button setImage:[self addBorderTo:image2] forState:UIControlStateSelected];
                
                [cell addSubview:button];
            }
        }
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    //list
    }else if (tableView.tag == 1) {
       
        NSNumber *num = [dict objectForKey:[self.items objectAtIndex:indexPath.row]];
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        
        //button
        UIButton  *button = nil;
        if (num.intValue < 0) {
            button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [button setTitle:@"Send" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithRed:(237.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0] forState:UIControlStateNormal];
            
        }else if (num.intValue == 0){
            button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button setHidden:YES];
            
        }else{
            button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            
            [button setTitle:@"Update" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithRed:(237.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0] forState:UIControlStateNormal];
        }
        [button setFrame:CGRectMake(self.view.frame.size.width-0.40625*self.view.frame.size.width, 0.0625*self.view.frame.size.width, 0.234375*self.view.frame.size.width, 0.109375*self.view.frame.size.width)];
        [button setTag:indexPath.row+10];
        [button addTarget:self action:@selector(listSendAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:button];
        if ([self.editButton.title isEqual: @"Done"]) [button setHidden:YES];
        
        
        NSMutableArray *annotation = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.items objectAtIndex:indexPath.row]]];
        UIImage *newimage = [[UIImage alloc]initWithContentsOfFile:[[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:[self.items objectAtIndex:indexPath.row]] ];


        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0375*self.view.frame.size.width, 0.0375*self.view.frame.size.width, 0.425*self.view.frame.size.width, 0.425*self.view.frame.size.width)];
        imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.paths objectAtIndex:THUMB],[self.items objectAtIndex:indexPath.row]]];
        UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.5*self.view.frame.size.width,  0.5*self.view.frame.size.width)];
        [imview addSubview:imageView];
        UIGraphicsBeginImageContext(CGSizeMake( 0.5*self.view.frame.size.width,  0.5*self.view.frame.size.width));
        
        [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView setImage:image];
        [cell.imageView addSubview:[self correctAccessoryAtIndex:indexPath.row withNum:num withSize:CGSizeMake(tableView.rowHeight, tableView.rowHeight)]];
        cell.detailTextLabel.numberOfLines = 2;
        NSString *detailText = [[NSString alloc]initWithFormat:@"%d objects\n%d x %d",annotation.count,(int)newimage.size.width,(int)newimage.size.height];
        cell.detailTextLabel.text = detailText;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSString *date = [[NSString alloc]initWithFormat:@"%@-%@-%@",[[self.items objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(4, 2)],[[self.items objectAtIndex:indexPath.row] substringWithRange:NSMakeRange(6, 2)],[[self.items objectAtIndex:indexPath.row] substringToIndex:4] ];
        cell.textLabel.text = date;
    }
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 0) return NO;
    
    else{
        UIButton *button =  (UIButton *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:indexPath.row+10];
        if (([button.titleLabel.text length]>0) && (![tableView isEditing]))
            button.hidden = NO;

        else button.hidden = YES;

        return YES;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1)
        [self imageDidSelectedWithIndex:indexPath.row];
}




#pragma mark -
#pragma mark SendingView
-(void)cancel
{
    [serverConnection cancelRequestFor:0];
    [self.selectedItemsSend removeAllObjects];
    [sendingView reset];
    [sendingView.progressView setProgress:0];
    [sendingView setHidden:YES];
    [self.tabBarController.tabBar setUserInteractionEnabled:YES];

    [self.editButton setEnabled:YES];
    [sendingView.activityIndicator stopAnimating];
    
    
}



#pragma mark
#pragma mark - ModalTVC Delegate


- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier
{
    dispatch_queue_t queue = dispatch_queue_create("DownloadQueue", NULL);

    //sending view preparation
//    self.navigationController.navigationBarHidden = YES;
    sendingView.total = selectedItems.count;
    [sendingView setHidden:NO];
    [sendingView.activityIndicator startAnimating];
    [sendingView.progressView setProgress:0];
    
    
    
    NSMutableArray *newIndexes = [[NSMutableArray alloc] init];
    if([identifier isEqualToString:@"Choose Labels"]){
        NSArray *labels = [self.downloadedLabelsMap allKeys];
        for(NSNumber *select in selectedItems){
            NSString *label = [labels objectAtIndex:select.intValue];
            NSArray *indexes = [self.downloadedLabelsMap objectForKey:label];
            [newIndexes addObjectsFromArray:indexes];
        }
        newIndexes = [[[NSSet setWithArray:newIndexes] allObjects] mutableCopy];
        
        selectedItems = newIndexes;
    }
    
    
    
    dispatch_async(queue, ^(void){
        __block int i=0;
        for(NSNumber *selectedIndex in selectedItems){
        
            NSString *imageName = [self.downloadedImageNames objectAtIndex:selectedIndex.intValue];
            
            //Save thumbnail
            NSString *pathThumb = [[self.paths objectAtIndex:THUMB ] stringByAppendingPathComponent:imageName];
            [[NSFileManager defaultManager] createFileAtPath:pathThumb contents:UIImageJPEGRepresentation([self.downloadedThumbnails objectAtIndex:selectedIndex.intValue], 1.0) attributes:nil];
            
            //Save annotation
            NSString *pathObject = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
            [NSKeyedArchiver archiveRootObject:[self.downloadedAnnotations objectAtIndex:selectedIndex.intValue] toFile:pathObject];

            
            //download and save images in a new thread
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self.downloadedImageUrls objectAtIndex:selectedIndex.intValue]]]];

            NSString *pathImages = [[self.paths objectAtIndex:IMAGES ] stringByAppendingPathComponent:imageName];
            [[NSFileManager defaultManager] createFileAtPath:pathImages contents:UIImageJPEGRepresentation(image, 1.0) attributes:nil];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.tagViewController setImage:image];
                [self.tagViewController setUsername:self.username];
                [self.tagViewController.annotationView reset];
                [self.tagViewController.annotationView.objects setArray:[self.downloadedAnnotations objectAtIndex:selectedIndex.intValue]];
                [self.tagViewController setFilename:imageName];
                self.tagViewController.forThumbnailUpdating = YES;
                [self.navigationController pushViewController:self.tagViewController animated:NO];
                
                [sendingView incrementNum];
                [sendingView.progressView setProgress:i*1.0/selectedItems.count];
                NSLog(@"Progress:%f", i*1.0/selectedItems.count);
                i++;
            });
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self reloadGallery];
            sendingView.hidden = YES;
            self.navigationController.navigationBarHidden = NO;
            self.tableViewGrid.hidden = NO;
            [sendingView.activityIndicator stopAnimating];
            [sendingView reset];
        });
        
    });
    
    dispatch_release(queue);

}

-(void) selectionCancelled{}


#pragma mark
#pragma mark -  Private Methods


- (NSArray *) getOrderedListOfFilesForPath:(NSString *)path
{
    
    NSMutableArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL] mutableCopy];
    NSMutableArray *filesAndProperties = [NSMutableArray arrayWithCapacity:[files count]];
    
    for(NSString *file in files) {
        NSString *filePath = [path stringByAppendingPathComponent:file];
        NSDictionary *properties = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSDate *modDate = (NSDate *)[properties objectForKey:NSFileModificationDate];
        [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                       file, @"path",
                                       modDate, @"lastModDate",nil]];
        
    }
    
    // sort using a block
    // order inverted as we want latest date first
    NSArray *sortedFiles = [filesAndProperties sortedArrayUsingComparator:^(id path1, id path2){
        
                                // compare
                                NSComparisonResult comp = [[path1 objectForKey:@"lastModDate"] compare:
                                                           [path2 objectForKey:@"lastModDate"]];
                                // invert ordering
                                return comp == NSOrderedAscending ? NSOrderedDescending : NSOrderedAscending;
                            }];
    
    [files removeAllObjects];
    for(NSDictionary *sortFile in sortedFiles)
        [files addObject:(NSString *)[sortFile objectForKey:@"path"]];
    
    return [NSArray arrayWithArray:files];
}


-(UIButton *) generateGetImagesButtonWithTitle:(NSString *)title atRect:(CGRect)rect
{
    //second button lower thant the first one
    CGFloat ini = 0;
    if([title isEqualToString:@"More Labels"]) ini = 50;
    
    UIButton *btnDeco = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnDeco.frame = rect;//CGRectMake(0, ini, 280, 40);
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake(btnDeco.bounds.size.width - btnDeco.bounds.size.height / 2 , btnDeco.bounds.size.height / 2);
    [btnDeco addSubview: indicator];
    btnDeco.backgroundColor = [UIColor clearColor];
    [btnDeco setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [btnDeco addTarget:self action:@selector(moreImagesAction:) forControlEvents:UIControlEventTouchUpInside];
    [btnDeco setTitle:title forState:UIControlStateNormal];
    
    return btnDeco;
}


- (UIView *) footerViewCreationAtHeight:(int)height
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, height, self.view.frame.size.width, 110)];
    
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cameraButton.frame = CGRectMake(10, 10, 280, 50);
//    [cameraButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
    cameraButton.contentMode = UIViewContentModeCenter;
    [cameraButton addTarget:self action:@selector(addImage:) forControlEvents:UIControlEventTouchUpInside];
    [cameraButton setTitle:@"Camera" forState:UIControlStateNormal];
    
    UIButton *imagesButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    imagesButton.frame = CGRectMake(10, cameraButton.frame.origin.y + cameraButton.frame.size.height +5, 130, 40);
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.center = CGPointMake(imagesButton.bounds.size.width - imagesButton.bounds.size.height / 2 , imagesButton.bounds.size.height / 2);
    [imagesButton addSubview: indicator];
    imagesButton.backgroundColor = [UIColor clearColor];
    [imagesButton addTarget:self action:@selector(moreImagesAction:) forControlEvents:UIControlEventTouchUpInside];
    [imagesButton setTitle:@"Server Images" forState:UIControlStateNormal];
    
    UIButton *labelsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    labelsButton.frame = CGRectMake(160, cameraButton.frame.origin.y + cameraButton.frame.size.height+5, 130, 40);
    UIActivityIndicatorView *indicator2 = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator2.center = CGPointMake(labelsButton.bounds.size.width - labelsButton.bounds.size.height / 2 , labelsButton.bounds.size.height / 2);
    [labelsButton addSubview: indicator2];
    labelsButton.backgroundColor = [UIColor clearColor];
    [labelsButton addTarget:self action:@selector(moreImagesAction:) forControlEvents:UIControlEventTouchUpInside];
    [labelsButton setTitle:@"Server Labels" forState:UIControlStateNormal];
    
    [footerView addSubview:cameraButton];
    [footerView addSubview:imagesButton];
    [footerView addSubview:labelsButton];
    
    return footerView;
}

@end
