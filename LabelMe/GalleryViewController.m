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
#import "CustomBadge.h"

#import "UIImage+Resize.h"
#import "UIImage+Border.h"
#import "NSObject+ShowAlert.h"
#import "NSObject+Folders.h"

#import "LMUINavigationController.h"
#import "UIButton+CustomViews.h"



@interface GalleryViewController()

//arrays to store information about downloaded images from server
@property (nonatomic, strong) NSMutableArray *downloadedThumbnails;
@property (nonatomic, strong) NSMutableArray *downloadedAnnotations;
@property (nonatomic, strong) NSMutableArray *downloadedImageUrls;
@property (nonatomic, strong) NSMutableArray *downloadedImageNames;
@property (nonatomic, strong) NSMutableDictionary *downloadedLabelsMap; //label -> array with indexes
@property (nonatomic, strong) NSMutableDictionary *labelsDictionary; //dictionary: label -> array of filenames containing label

@property (nonatomic, strong) NSArray *labelsOrdered; //ordered labels names
@property (nonatomic, strong) NSMutableDictionary *buttonsDictionary; //buttons stored to select all images when section name tapped

@property BOOL cancelDownloading;


//show/hide tabBarcontroller for the sending view
- (void)hideTabBar:(UITabBarController *) tabbarcontroller;
- (void)showTabBar:(UITabBarController *) tabbarcontroller;

//generate thumbnail image with the boxes from an image given
- (UIImage *) thumbnailImageFromImage:(UIImage *)image withBoxes:(NSArray *)boxes;

@end


@implementation GalleryViewController


#pragma mark
#pragma mark - Getters 

- (NSArray *) paths
{
    if(!_paths){
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:self.username];
        
        _paths = [NSArray arrayWithObjects:[path stringByAppendingPathComponent:@"images"],[path stringByAppendingPathComponent:@"thumbnail"],[path stringByAppendingPathComponent:@"annotations"],path, nil];
    }
    return _paths;
}


- (NSArray *) items
{
    if(!_items){
        NSString *path = [self.paths objectAtIndex:IMAGES];
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
        
        _items = [NSArray arrayWithArray:files];
    }
    return _items;
}

-(NSMutableDictionary *) labelsDictionary
{
    if(!_labelsDictionary){
     
        _labelsDictionary = [[NSMutableDictionary alloc] init];
        for(NSString *filename in self.items){
            
            //get the boxes
            NSString *boxesPath = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
            NSArray *boxes = [[NSArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:boxesPath]];
            
            for(Box *box in boxes){
                NSString *label;
                if([box.label isEqualToString:@""]) label = @"00None"; else label = box.label;
                NSMutableArray *currentFilenames = (NSMutableArray *)[_labelsDictionary objectForKey:label];
                if(!currentFilenames) currentFilenames = [[NSMutableArray alloc] init];
                [currentFilenames addObject:filename];
                [_labelsDictionary setObject:currentFilenames forKey:label];
            }
            if(boxes.count==0){ //no labels
                NSMutableArray *currentFilenames = (NSMutableArray *)[_labelsDictionary objectForKey:@"00None"];
                if(!currentFilenames) currentFilenames = [[NSMutableArray alloc] init];
                [currentFilenames addObject:filename];
                [_labelsDictionary setObject:currentFilenames forKey:@"00None"];
            }
        }
    }
    
    return _labelsDictionary;
}


- (NSArray *) labelsOrdered
{
    if(!_labelsOrdered) _labelsOrdered = [[self.labelsDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return _labelsOrdered;
}

- (NSMutableDictionary *) buttonsDictionary
{
    if(!_buttonsDictionary){
        
        _buttonsDictionary = [[NSMutableDictionary alloc] init];
        for (NSString *label in self.labelsOrdered){
            NSArray *indexes = [self.labelsDictionary objectForKey:label];
            NSMutableArray *buttons = [[NSMutableArray alloc] init];
            for(int i=0; i<indexes.count; i++){
                
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.tag = [self.items indexOfObject:[indexes objectAtIndex:i]];
                
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                    button.frame = CGRectMake(0.05*self.view.frame.size.width + 0.225*self.view.frame.size.width*(i%4),
                                              0.01875*self.view.frame.size.width + 0.225*self.view.frame.size.width*(floor((i/4))),
                                              0.225*self.view.frame.size.width - 5,
                                              0.225*self.view.frame.size.width - 5);
                
                else button.frame = CGRectMake(0.07*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4),
                                               0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))),
                                               0.2*self.view.frame.size.width - 7,
                                               0.2*self.view.frame.size.width - 7);
                
                button.titleLabel.text = label;
                UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:[[self.paths objectAtIndex:THUMB] stringByAppendingPathComponent:[indexes objectAtIndex:i]]];
                
                [button addTarget:self
                           action:@selector(buttonClicked:)
                 forControlEvents:UIControlEventTouchUpInside];
                [button setImage:thumbnailImage forState:UIControlStateNormal];
                
                //custom badge
                NSNumber *num = [self.userDictionary objectForKey:[indexes objectAtIndex:i]];
                [button addSubview:[self correctAccessoryWithBoxes:num forImgeSize:button.frame.size]];
                
                [buttons addObject:button];
            }
            [_buttonsDictionary setObject:buttons forKey:label];
        }
    }
    return _buttonsDictionary;
}



-(NSMutableDictionary *)userDictionary
{
    if(!_userDictionary)
        _userDictionary = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    return _userDictionary;
}



#pragma mark -
#pragma mark lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //objects initialization
        self.selectedItems = [[NSMutableArray alloc]init];
        self.selectedItemsSend = [[NSMutableArray alloc]init];
        self.selectedItemsDelete = [[NSMutableArray alloc]init];
        self.serverConnection = [[ServerConnection alloc] init];
        
        //tab bar
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Gallery" image:nil tag:0];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"home.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"homeActive.png"]];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    
    self.serverConnection.delegate = self;
    self.title = @"Gallery"; //for back button
    photosWithErrors = 0;
    
    //Controllers
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([UIScreen mainScreen].bounds.size.height == 568)
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone5" bundle:nil];
        else if ([UIScreen mainScreen].bounds.size.height == 480)
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone" bundle:nil];
    }else self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPad" bundle:nil];
    self.tagViewController.username = self.username;
    self.tagViewController.delegate = self;
    self.modalSectionsTVC = [[ModalSectionsTVC alloc] initWithNibName:@"ModalSectionsTVC" bundle:nil];
    self.cameraVC = [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil];
    self.cameraVC.delegate = self;
    
    //GPS settings
    self.locationMng = [[CLLocationManager alloc] init];
    self.locationMng.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    //bottom bar when edit pressed
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];

    //titleView: LabelMe Logo and title images
    UIImage *titleImage = [UIImage imageNamed:@"galleryTitle.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    titleView.image = titleImage;
    [self.navigationItem setTitleView:titleView];
    
    //Buttons
    self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteAction:)];
    [self.deleteButton setTintColor:[UIColor redColor]];
    [self.deleteButton setWidth:self.view.frame.size.width/2 - 11];
    [self.deleteButton setEnabled:NO];
    self.editButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton buttonBarWithTitle:@"Edit" target:self action:@selector(editAction:)]];
    self.navigationItem.rightBarButtonItem = self.editButton;
    self.sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleBordered target:self action:@selector(sendAction:)];
    [self.sendButton setWidth:self.view.frame.size.width/2 - 11];
    [self.sendButton setEnabled:NO];
    [self.downloadButton highlightButton];
    self.activityIndicator.hidden = YES;
    [self.cameraButton highlightButton];
    self.cameraButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.cameraButton setImage:[UIImage imageNamed:@"cameraIcon.png"] forState:UIControlStateNormal];
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
    
    //noImages view
    self.noImages = [[UILabel alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x+0.03125*self.view.frame.size.width, self.tableView.frame.origin.y+0.03125*self.view.frame.size.width, self.tableView.frame.size.width-0.0625*self.view.frame.size.width, self.tableView.frame.size.height-0.0625*self.view.frame.size.width)];
    [self.noImages setBackgroundColor:[UIColor whiteColor]];
    self.noImages.layer.masksToBounds = YES;
    self.noImages.layer.cornerRadius = 10.0;
    self.noImages.layer.shadowColor = [UIColor grayColor].CGColor;
    self.noImages.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    self.noImages.shadowColor = [UIColor grayColor];
    [self.noImages setNumberOfLines:2];
    self.noImages.shadowOffset = CGSizeMake(0.0, 1.0);
    self.noImages.text = @"You do not have images, \nstart taking pics and labeling or download from web!";
    [self.noImages setTextAlignment:NSTextAlignmentCenter];
    [self.noImages setUserInteractionEnabled:YES];
    
    //sendingView 
    self.sendingView = [[SendingView alloc] initWithFrame:self.tabBarController.view.frame];
//    NSLog(@"view height: %f, tabBarContorller height: %f", self.view.frame.size.height, self.tabBarController.view.frame.size.height);
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.sendingView setHidden:YES];
    self.sendingView.delegate = self;
    self.sendingView.textView.text = @"Uploading image to server";

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.tableViewGrid];
    [self.view addSubview:self.noImages];
    [self.view addSubview:self.sendingView];
    
    [self reloadGallery];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //solid color for the navigation bar
    [self.navigationController.navigationBar setBackgroundImage:[LMUINavigationController drawImageWithSolidColor:[UIColor redColor]] forBarMetrics:UIBarMetricsDefault];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    //disable edit state if interrupted
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
    dispatch_queue_t saveQueue = dispatch_queue_create("saveQueue", NULL);
    dispatch_async(saveQueue, ^{
        self.items = nil;
        self.labelsDictionary = nil;
        self.labelsOrdered = nil;
        self.buttonsDictionary = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{

            if(self.items.count == 0) {
                self.noImages.hidden = NO;
                self.tableView.hidden = YES;
                self.tableViewGrid.hidden = YES;
            }
            else self.noImages.hidden = YES;
            
            [self.tableView reloadData];
            [self.tableViewGrid reloadData];
        });
    });
    dispatch_release(saveQueue);
}



- (UIView *)correctAccessoryWithBoxes:(NSNumber *)num forImgeSize:(CGSize)size
{
    UIView *ret = nil;
    CGSize size2 = size;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        size2 = CGSizeMake(80, 80);

        
    if (num.intValue == 0){ // All images sent
        UIImageView *accessory =  [[UIImageView alloc] initWithFrame:CGRectMake(size.width - 0.25*size2.width, 0, 0.25*size2.width, 0.25*size2.width)];
        accessory.image = [UIImage imageNamed:@"tick.png"];
        ret = accessory;
        
    }else{
        int number = num.intValue < 0 ? abs(num.intValue+1):num.intValue;
        UIColor *color = num.intValue < 0 ? [UIColor redColor]:[UIColor orangeColor];
        NSString *numberString = [NSString stringWithFormat:@"%d", number];
        CustomBadge *accessory = [CustomBadge customBadgeWithString:numberString withStringColor:[UIColor whiteColor] withInsetColor:color withBadgeFrame:YES withBadgeFrameColor:[UIColor whiteColor] withScale:1.0 withShining:YES];
        accessory.frame = CGRectMake(size.width- 0.30*size2.width, 0, 0.30*size2.width, 0.30*size2.width);
        ret = accessory;
    }
    
    return  ret;
}





#pragma mark -
#pragma mark IBActions

-(IBAction)editAction:(id)sender
{
    UIButton *editButton = [self.editButton valueForKey:@"view"];
    //grid
    if (!self.listButton.isSelected) {
        if ([editButton.titleLabel.text isEqual: @"Edit"]) {
            [self.listButton setHidden:YES];
            [editButton setTitle:@"Cancel" forState:UIControlStateNormal];
            [self.navigationController setToolbarHidden:NO];
            NSArray *toolbarItems = [[NSArray alloc] initWithObjects:self.sendButton,self.deleteButton, nil];
            [self.navigationController.toolbar setItems:toolbarItems];
            [self.tableViewGrid setFrame:CGRectMake(self.tableViewGrid.frame.origin.x, self.tableViewGrid.frame.origin.y, self.tableViewGrid.frame.size.width, self.tableViewGrid.frame.size.height - self.navigationController.toolbar.frame.size.height)];
            
        }else{
            [editButton setTitle:@"Edit" forState:UIControlStateNormal];
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
    [self.navigationController pushViewController:self.cameraVC animated:NO];

}

- (IBAction)downloadAction:(id)sender
{
    
    //start spin indicator for the activity
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    dispatch_queue_t q = dispatch_queue_create("q", NULL);
    dispatch_async(q, ^{
        
        NSString *query = [NSString stringWithFormat:@"http://labelme2.csail.mit.edu/developers/mingot/LabelMe3.0/iphoneAppTools/download.php?username=%@", self.username];
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
                
                //get and save thumb
                NSString *thumbUrl = [element objectForKey:@"thumb"];
                UIImage *thumbImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:thumbUrl]]];
                if(thumbImage!=nil) [self.downloadedThumbnails addObject:thumbImage];
                else [self.downloadedThumbnails addObject:[UIImage imageNamed:@"image_not_found.png"]];
                
                //get and save images urls
                NSString *imageUrl = [element objectForKey:@"image"];
                [self.downloadedImageUrls addObject:imageUrl];
                
                //get and save annotations
                NSMutableArray *boundingBoxes = [[NSMutableArray alloc] init];
                NSDictionary *annotation = (NSDictionary *) [element objectForKey:@"annotation"];
                NSDictionary *imageSize;
                if([annotation isKindOfClass:[NSDictionary class]]) imageSize = (NSDictionary *) [annotation objectForKey:@"imagesize"];
                else continue; //skip image
                
                id objects = [annotation objectForKey:@"object"];
                NSArray *boxes;
                if([objects isKindOfClass:[NSArray class]]) boxes = (NSArray *) objects;
                else boxes = [[NSArray alloc] initWithObjects:(NSDictionary *)objects, nil];
                
                for(NSDictionary *box in boxes){
                    
                    //label: insert into the map to download specific images for a given label
                    NSString *label;
                    if([[box objectForKey:@"name"] isKindOfClass:[NSString class]])
                        label = [(NSString *) [box objectForKey:@"name"] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    else continue; //skip box
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
                }
                
                //save the dictionary
                [self.downloadedAnnotations addObject:boundingBoxes];
            }
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.activityIndicator.hidden = YES;
            [self.activityIndicator stopAnimating];
            
            //present the modal depending on the sender button: show images or labels
            if(self.downloadedThumbnails.count>0){

                self.modalSectionsTVC = [[ModalSectionsTVC alloc] init];
                self.modalSectionsTVC.showCancelButton = YES;
                self.modalSectionsTVC.delegate = self;
                self.modalSectionsTVC.modalTitle = @"Choose Images";
                self.modalSectionsTVC.thumbnailImages = self.downloadedThumbnails;
                self.modalSectionsTVC.dataDictionary = self.downloadedLabelsMap;
                [self presentModalViewController:self.modalSectionsTVC animated:YES];
                    
            }else{
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Empty"
                                                                     message:@"You have all the images"
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                [errorAlert show];
            }
        });
        
    });

}

-(IBAction)buttonClicked:(id)sender
{
    UIButton *button = (UIButton *)sender;
    UIButton *editButton = [self.editButton valueForKey:@"view"];
    
    
    if ([editButton.titleLabel.text isEqual: @"Cancel"]) {
        if ([self.selectedItems containsObject:[self.items objectAtIndex:button.tag]]) {
            [self.selectedItems removeObject:[self.items objectAtIndex:button.tag]];
            [button setSelected:NO];
            button.layer.borderWidth = 0;
            
        }else{
            [self.selectedItems addObject:[self.items objectAtIndex:button.tag]];
            [button setSelected:YES];
            button.layer.borderColor = [UIColor colorWithRed:(160/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0].CGColor;
            button.layer.borderWidth = 4;

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
    }else [self imageDidSelectedWithIndex:button.tag forObjectClass:button.titleLabel.text];
}



-(void)imageDidSelectedWithIndex:(int)selectedImage forObjectClass:(NSString *)objectClass
{
    NSString *filename = (NSString *)[self.items objectAtIndex:selectedImage];
    
//    //only scroll view of the objects of the same class.
//    NSMutableArray *items = [[NSMutableArray alloc] init];
//    if([objectClass isEqualToString:@""]){
//        items = [NSMutableArray arrayWithArray:self.items];
//    }else items = [NSMutableArray arrayWithArray:[self.labelsDictionary objectForKey:objectClass]];

    //load tagVC
    self.tagViewController.items = self.items;
    self.tagViewController.filename = filename;
    self.tagViewController.userDictionary = self.userDictionary;
    self.tagViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.tagViewController animated:YES];
}


-(IBAction)listSendAction:(id)sender
{
    self.sendingView.total = self.selectedItemsSend.count;
    [self.sendingView setHidden:NO];
    [self.sendingView.activityIndicator startAnimating];
    
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
    NSString *str;
    if (self.selectedItems.count == 1) str = @"Delete Selected Photo";
    else str = [[NSString alloc] initWithFormat:@"Delete %d Selected Photos",self.selectedItems.count];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:str otherButtonTitles:nil, nil];
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    actionSheet.tag = 0;
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
}

-(IBAction)sendAction:(id)sender
{
    [self.selectedItemsSend addObjectsFromArray:self.selectedItems];
    [self.sendingView.activityIndicator startAnimating];
    [self.sendingView setHidden:NO];
    [self.sendingView setTotal:self.selectedItemsSend.count];
    [self.sendingView.progressView setProgress:0];
    self.sendingView.sendingViewID = @"upload";
    [self hideTabBar:self.tabBarController];

    [self.editButton setEnabled:NO];
    photosWithErrors = 0;
    [self sendPhoto];
    [self.selectedItems removeAllObjects];
    [self editAction: self.editButton];
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
    [self.serverConnection cancelRequestFor:0];

    [self.selectedItemsSend removeAllObjects];
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
    NSFileManager *filemng = [NSFileManager defaultManager];
    if (![filemng removeItemAtPath:[[self.paths objectAtIndex:THUMB] stringByAppendingPathComponent:[self.selectedItemsDelete objectAtIndex:index]] error:&error]) {
        [NSKeyedArchiver archiveRootObject:self.userDictionary toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.selectedItems objectAtIndex:index]]];
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Error" message:@"It can not be removed." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
    }
    else {
        UIImage *thumim =  [UIImage imageWithContentsOfFile:[[self.paths objectAtIndex:THUMB] stringByAppendingPathComponent:[self.selectedItemsDelete objectAtIndex:index]]];
        
        if (![filemng removeItemAtPath:[[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:[self.selectedItemsDelete objectAtIndex:index]] error:&error]) {
            NSData *thum = UIImageJPEGRepresentation(thumim, 0.75);
            [NSKeyedArchiver archiveRootObject:self.userDictionary toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[self.selectedItemsDelete objectAtIndex:index]]];
            [filemng createFileAtPath:[[self.paths objectAtIndex:THUMB] stringByAppendingPathComponent:[self.selectedItemsDelete objectAtIndex:index]] contents:thum attributes:nil];
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
            [self.userDictionary removeObjectForKey:[self.selectedItemsDelete objectAtIndex:index]];
        }
    }
    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:YES];
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
    NSNumber *num = [self.userDictionary objectForKey:[self.selectedItemsSend objectAtIndex:0]];

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
        [self.serverConnection sendPhoto:image filename:[self.selectedItemsSend objectAtIndex:0] path:[self.paths objectAtIndex:OBJECTS] withSize:point andAnnotation:annotation];
    
    // Photo is in the server, overwrite the annotation
    else [self.serverConnection updateAnnotationFrom:[self.selectedItemsSend objectAtIndex:0] withSize:point :annotation];
    
}

#pragma mark -
#pragma mark CameraVC Delegate

-(void) addImageCaptured:(UIImage *)image
{
    dispatch_queue_t savingQueue = dispatch_queue_create("saving_image", 0);
    dispatch_async(savingQueue, ^{
        
        NSDictionary *userDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[self.userPaths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
        
        [self.locationMng startUpdatingLocation];
        
        //get the new size of the image according to the defined resolution and save image
        CGSize newSize = image.size;
        float resolution = [[userDictionary objectForKey:@"resolution"] floatValue];
        float max = newSize.width > newSize.height ? newSize.width : newSize.height;
        if ((resolution != 0.0) && (resolution < max))
            newSize = image.size.height > image.size.width ? CGSizeMake(resolution*0.75, resolution) : CGSizeMake(resolution, resolution*0.75);
        
        //save image into library if option enabled in settings
        if ([[userDictionary objectForKey:@"cameraroll"] boolValue]) UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        //save location information
        NSString *location = @"";
        location = [[self.locationMng.location.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
        //TODO: FIX THIS!!
//        [location writeToFile:[[self.userPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[[tagViewController.filename stringByDeletingPathExtension] stringByAppendingString:@".txt"]] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
        [self.locationMng stopUpdatingLocation];
        
        [self saveImage:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self reloadGallery];
            self.tableViewGrid.hidden = NO;
        });
    });
    dispatch_release(savingQueue);
}

#pragma mark -
#pragma mark Save image and Filename

-(void)saveImage:(UIImage *)image
{
    if (self.paths == nil)
        self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];
    
    //set self.filename
    NSString *filename = [self createFilename];
    [self createPlistEntry:filename];
    
    NSString *pathImages = [[self.paths objectAtIndex:IMAGES ] stringByAppendingPathComponent:filename];
    [[NSFileManager defaultManager] createFileAtPath:pathImages contents:UIImageJPEGRepresentation(image, 1.0) attributes:nil];
    
    NSString *pathThumb = [[self.paths objectAtIndex:THUMB ] stringByAppendingPathComponent:filename];
    [[NSFileManager defaultManager] createFileAtPath:pathThumb contents:UIImageJPEGRepresentation([image thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil];
}


-(void)createPlistEntry:(NSString *)filename
{
    [self.sendButton setTitle:@"Send"];
    [self.userDictionary setObject:[[NSNumber alloc] initWithInt:-1] forKey:filename];
    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
}


-(NSString *) createFilename
{
    NSString *date = [[NSString alloc]initWithString:[[[NSDate date] description] substringToIndex:19]];
    date = [date stringByReplacingOccurrencesOfString:@" " withString:@""];
    date = [date stringByReplacingOccurrencesOfString:@"-" withString:@""];
    date = [date stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    return [date stringByAppendingFormat:@"%@.jpg",self.username];
}

#pragma mark -
#pragma mark TagVC Delegate

- (void) reloadTableOnImageGallery
{
    [self reloadGallery];
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
    
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:0];
    [self.userDictionary removeObjectForKey:filename];
    [self.userDictionary setObject:newdictnum forKey:filename];
    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    if (self.selectedItemsSend.count > 0) {
        [self.sendingView.progressView setProgress:0];
        [self.sendingView incrementNum];
        [self sendPhoto];
    }
    else{
        if (photosWithErrors >0) {
            if (photosWithErrors == 1)
                [self errorWithTitle:@"An image could not be sent" andDescription:@"Please, try again."];
            else [self errorWithTitle:[NSString stringWithFormat:@"%d images could not be sent.",photosWithErrors] andDescription:@"Please, try again."];
        }
        [self.sendingView reset];
        [self.sendingView setHidden:YES];
        [self showTabBar:self.tabBarController];

        [self.editButton setEnabled:YES];
        [self.sendingView.activityIndicator stopAnimating];

    }
    [self reloadGallery];
}


-(void)sendingProgress:(float)prog
{
    [self.sendingView.progressView setProgress:prog];
}


-(void)sendPhotoError
{
    photosWithErrors++;
    [self.selectedItemsSend removeObjectAtIndex:0];
    if (self.selectedItemsSend.count > 0) {
        [self.sendingView.progressView setProgress:0];
        [self.sendingView incrementNum];
        [self sendPhoto];
    }
    else if (photosWithErrors > 0 ){
        if (photosWithErrors == 1) {
            [self errorWithTitle:@"An image could not be sent" andDescription:@"Please, try again."];
        }
        else{
            [self errorWithTitle:[NSString stringWithFormat:@"%d images could not be sent.",photosWithErrors] andDescription:@"Please, try again."];
        }
        [self.sendingView reset];
        [self.sendingView setHidden:YES];
        [self.sendingView.activityIndicator stopAnimating];
        
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];
        [self.editButton setEnabled:YES];
    }
}
                 
-(void)photoNotOnServer:(NSString *)filename
{
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    if (objects != nil) {
        for (int i=0; i<objects.count; i++)
            [[objects objectAtIndex:i] setSent:NO];
        
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    }
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:(-objects.count-1)];
    [self.userDictionary removeObjectForKey:filename];
    [self.userDictionary setObject:newdictnum forKey:filename];
    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    if (self.selectedItemsSend.count > 0) {
        [self sendPhoto];
    }
    else{

        [self.sendingView reset];
        [self.sendingView setHidden:YES];
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];

        [self.editButton setEnabled:YES];
        [self.sendingView.activityIndicator stopAnimating];

    }
    [self reloadGallery];
}


         

#pragma mark -
#pragma mark TableView Delegate&Datasource

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    NSString *title;
    if(tableView.tag==0){
        NSString *label = [self.labelsOrdered objectAtIndex:section];
        if([label isEqualToString:@"00None"]) label = @"None";
        NSArray *items = [self.labelsDictionary objectForKey:label];
        title = [NSString stringWithFormat:@"%@ (%d)", label, items.count];
    }else title = @"";
    
    // create the parent view that will hold header Label
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(10,0,tableView.frame.size.width,30)];
    customView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:.9];
    customView.layer.borderWidth = 1.0;
    customView.layer.borderColor = [UIColor colorWithRed:220/256.0 green:0 blue:0 alpha:1.0].CGColor;
    
    // create the label objects
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:12];
    headerLabel.frame = CGRectMake(20,5,200,20);
    headerLabel.text =  title;
    headerLabel.textColor = [UIColor whiteColor];
    
    [customView addSubview:headerLabel];

    return customView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30; 
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView.tag==0) return self.labelsOrdered.count;
    else return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.tag==0){
        NSArray *items = [self.labelsDictionary objectForKey:[self.labelsOrdered objectAtIndex:indexPath.section]];
        return (0.225*self.view.frame.size.width*ceil((float)items.count/4) + 0.0375*self.view.frame.size.width);
    }else return tableView.rowHeight;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = 0;
    
    if (tableView.tag == 0 && (self.items.count>0)) ret = 1;
    else if (tableView.tag == 1) ret = self.items.count;
    
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
    
    //grid
    if (tableView.tag == 0) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        NSArray *buttons = [self.buttonsDictionary  objectForKey:[self.labelsOrdered objectAtIndex:indexPath.section]];
        for(UIButton *button in buttons) [cell addSubview:button];
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    //list
    }else if (tableView.tag == 1) {
       
        NSNumber *num = [self.userDictionary objectForKey:[self.items objectAtIndex:indexPath.row]];
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
        [cell.imageView addSubview:[self correctAccessoryWithBoxes:num forImgeSize:CGSizeMake(tableView.rowHeight, tableView.rowHeight)]];
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
    
    UIButton *button =  (UIButton *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:indexPath.row+10];
    
    if (([button.titleLabel.text length]>0) && (![tableView isEditing])) button.hidden = NO;
    else button.hidden = YES;

    return YES;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 1)
        [self imageDidSelectedWithIndex:indexPath.row forObjectClass:@""];
}



#pragma mark -
#pragma mark SendingView
-(void)cancel
{
    if([self.sendingView.sendingViewID isEqualToString:@"upload"]){
        [self.serverConnection cancelRequestFor:0];
        [self.selectedItemsSend removeAllObjects];
        [self.editButton setEnabled:YES];
        
        [self.sendingView reset];
        [self showTabBar:self.tabBarController];
        [self.sendingView setHidden:YES];
        [self.sendingView.activityIndicator stopAnimating];
        [self reloadGallery];
    
    }else if([self.sendingView.sendingViewID isEqualToString:@"download"])
        self.cancelDownloading = YES;
}



#pragma mark -
#pragma mark ModalSectionsTVC Delegate


- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier
{
    //sending view preparation
    [self hideTabBar:self.tabBarController];
    [self.sendingView setHidden:NO];
    self.sendingView.cancelButton.hidden = NO;
    [self.sendingView.activityIndicator startAnimating];
    [self.sendingView.progressView setProgress:0];
    self.sendingView.textView.text = @"Download initiated";
    self.sendingView.sendingViewID = @"download";
    
    self.cancelDownloading = NO;
    dispatch_queue_t queue = dispatch_queue_create("DownloadQueue", NULL);
    dispatch_async(queue, ^(void){
        
        for(int i=0;i<selectedItems.count && !self.cancelDownloading; i++){ //for each image selected
            
            NSNumber *selectedIndex = [selectedItems objectAtIndex:i];
            NSString *imageName = [self.downloadedImageNames objectAtIndex:selectedIndex.intValue];
                        
            //Save annotation
            NSString *pathObject = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
            [NSKeyedArchiver archiveRootObject:[self.downloadedAnnotations objectAtIndex:selectedIndex.intValue] toFile:pathObject];

            //download and save image 
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[self.downloadedImageUrls objectAtIndex:selectedIndex.intValue]]]];
            NSString *pathImages = [[self.paths objectAtIndex:IMAGES ] stringByAppendingPathComponent:imageName];
            [[NSFileManager defaultManager] createFileAtPath:pathImages contents:UIImageJPEGRepresentation(image, 1.0) attributes:nil];
            
            //Save thumbnail
            UIImage *thumbnailImage = [self thumbnailImageFromImage:image withBoxes:[self.downloadedAnnotations objectAtIndex:selectedIndex.intValue]];
            NSString *pathThumb = [[self.paths objectAtIndex:THUMB ] stringByAppendingPathComponent:imageName];
            [[NSFileManager defaultManager] createFileAtPath:pathThumb contents:UIImageJPEGRepresentation(thumbnailImage, 1.0) attributes:nil];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.sendingView.textView.text = [NSString stringWithFormat:@"Downloading from LabelMe Server... %d/%d",i+1,selectedItems.count];
                [self.sendingView.progressView setProgress:(i+1)*1.0/selectedItems.count];
            });

            
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(self.cancelDownloading){
                self.sendingView.textView.text = @"Download cancelled.";
                [self performSelector:@selector(hideSendingiew) withObject:nil afterDelay:1];
            }else [self hideSendingiew];
        });

    });
    
    dispatch_release(queue);
}


- (void) hideSendingiew
{
    [self reloadGallery];
    self.sendingView.hidden = YES;
    [self showTabBar:self.tabBarController];
    self.tableViewGrid.hidden = NO;
    [self.sendingView.activityIndicator stopAnimating];
}


-(void) selectionCancelled{}


#pragma mark -
#pragma mark Private Methods


- (void)viewDidUnload {
    [self setDownloadButton:nil];
    [self setCameraButton:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}

// Method implementations
- (void)hideTabBar:(UITabBarController *) tabbarcontroller
{
    self.navigationController.navigationBarHidden = YES;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    
    for(UIView *view in tabbarcontroller.view.subviews){
        if([view isKindOfClass:[UITabBar class]])
            [view setFrame:CGRectMake(view.frame.origin.x, 480, view.frame.size.width, view.frame.size.height)];
        
        else [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 480)];
    }
    
    [UIView commitAnimations];
}

- (void)showTabBar:(UITabBarController *) tabbarcontroller
{
    self.navigationController.navigationBarHidden = NO;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    for(UIView *view in tabbarcontroller.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
            [view setFrame:CGRectMake(view.frame.origin.x, 431, view.frame.size.width, view.frame.size.height)];
        
        else [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 431)];
        
    }
    
    [UIView commitAnimations];
}


- (UIImage *) thumbnailImageFromImage:(UIImage *)image withBoxes:(NSArray *)boxes
{
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blueColor] setStroke];
    
    CGContextSetLineWidth(ctx, 60);
    CGContextSetStrokeColorWithColor(ctx, [UIColor blueColor].CGColor);
    
    for(Box *box in boxes){
        CGRect rectangle = [box getRectangleForBox];
        CGContextStrokeRect(ctx, rectangle);
    }
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //generate thumbnail
    int thumbnailSize = 300;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) thumbnailSize = 128;
    UIImage *thumbnailImage = [[UIImage imageWithCGImage:resultingImage.CGImage] thumbnailImage:thumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    
    
    return thumbnailImage;
}

@end
