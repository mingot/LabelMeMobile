//
//  AnnotationToolViewController.m
//  AnnotationTool
//
//  Created by Dolores Blanco Almazán on 31/03/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "TagViewController.h"
#import "Constants.h"
#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>
#import "GalleryViewController.h"
#import "NSObject+Folders.h"
#import "ServerConnection.h"
#import "UITextField+CorrectOrientation.h"
#import "NSObject+ShowAlert.h"
#import "NSString+checkValidity.h"
#import "LMUINavigationController.h"
#import "UIButton+CustomViews.h"


@interface TagViewController()

//UIScroll view
//@property int currentScrollIndex;
//@property (nonatomic, strong) NSMutableArray *composeViewsArray; //array of compose views to set in each part of the scroll view.

// instructions to execute when loading and unloading images
- (void) loadWhenAppear;
- (void) loadWhenDisappear;

@end


@implementation TagViewController


#pragma mark -
#pragma mark Getters and Setters

//- (NSMutableArray *) composeViewsArray
//{
//    if(!_composeViewsArray){
//        _composeViewsArray = [[NSMutableArray alloc] initWithCapacity:self.items.count];
//        for(int i=0;i<self.items.count;i++)
//            [_composeViewsArray addObject:[NSNull null]];
//    }
//    return _composeViewsArray;
//}


#pragma mark -
#pragma mark View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.labelsView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        sConnection = [[ServerConnection alloc] init];
        sConnection.delegate = self;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbarBg.png"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    
    //disable keyboard when touching the background
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardAction:)];
    // For selecting cell.
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tagView addGestureRecognizer:gestureRecognizer];
    
    
    //bottom toolbar
    [self.bottomToolbar setBarStyle:UIBarStyleBlackOpaque];
    
    UIButton *addButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [addButtonView setImage:[UIImage imageNamed:@"newLabel.png"] forState:UIControlStateNormal];
    [addButtonView addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    self.addButton.customView = addButtonView;
    
    UIButton *deleteButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [deleteButtonView setImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    [deleteButtonView addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    self.deleteButton.customView = deleteButtonView;
    [self.deleteButton setEnabled:NO];
    [self.deleteButton setStyle:UIBarButtonItemStyleBordered];
    
    UIButton *sendButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,self.bottomToolbar.frame.size.height)];
    [sendButtonView setImage:[UIImage imageNamed:@"send.png"] forState:UIControlStateNormal];
    [sendButtonView addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.customView = sendButtonView;

    self.labelsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,self.bottomToolbar.frame.size.height)];
    [self.labelsButton setImage:[UIImage imageNamed:@"labelsList.png"] forState:UIControlStateNormal];
    [self.labelsButton setImage:[UIImage imageNamed:@"labelsList-white.png"] forState:UIControlStateSelected];
    [self.labelsButton addTarget:self action:@selector(listAction:) forControlEvents:UIControlEventTouchUpInside];
    self.labelsButtonItem.customView = self.labelsButton;
    

    //Scroll view
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
	[self.scrollView setCanCancelContentTouches:NO];
	self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
	self.scrollView.clipsToBounds = YES;		
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.delegate = self;
    
    //labels (for labeling a new object)
    [self.label setBorderStyle:UITextBorderStyleNone];
    [self.label setKeyboardAppearance:UIKeyboardAppearanceAlert];
    
    //labelsview (for the table showing the boxes in the image)
    [self.labelsView setBackgroundColor:[UIColor clearColor]];
    [self.labelsView setHidden:YES];
    [self.labelsView setDelegate:self];
    [self.labelsView setDataSource:self];
    [self.labelsView setRowHeight:30];
    self.labelsView.scrollEnabled = NO;
    UIImage *globo = [[UIImage imageNamed:@"globo4.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )];
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.scrollView.frame];
    [backgroundView setImage:globo];
    [self.labelsView setBackgroundView:backgroundView];


    //tip
    self.tip = [[UIButton alloc] initWithFrame:CGRectMake(25, 2*self.scrollView.frame.size.height/3, self.scrollView.frame.size.width/2, self.scrollView.frame.size.height/3)];
    [self.tip setBackgroundImage:[[UIImage imageNamed:@"globo.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )] forState:UIControlStateNormal];
    UILabel *tiplabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, self.tip.frame.size.width-24, self.tip.frame.size.height-24)];
    tiplabel.numberOfLines = 4;
    tiplabel.text = @"Tip:\nPress this button \nto add a bounding box!";
    tiplabel.textColor = [UIColor redColor];
    tiplabel.backgroundColor = [UIColor clearColor];
    [self.tip addSubview:tiplabel];
    [self.tip addTarget:self action:@selector(hideTip:) forControlEvents:UIControlEventTouchUpInside];
    if ((self.items.count>1) || (self.tagView.boxes.count != 0))
        self.tip.hidden = YES;

    //sending view
    self.sendingView.hidden = YES;
    self.sendingView.textView.text = @"Uploading to the server...";
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.sendingView.delegate = self;

    //model
    self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];
    
    //annotation view
    self.tagView.delegate = self;

    //Next and previous buttons
    self.nextButton.tag = 2;
    self.previousButton.tag = 1;

    //subview hierarchy
    [self.scrollView setContentSize:self.scrollView.frame.size];
    [self.scrollView addSubview:self.composeView];
    [self.scrollView addSubview:self.tip];
    [self.scrollView addSubview:self.nextButton];
    [self.scrollView addSubview:self.previousButton];
    [self.scrollView addSubview:self.label];
    [self.scrollView addSubview:self.labelsView];
    [self.scrollView addSubview:self.sendingView];
    
}


- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    //solid color for the navigation bar
    [self.navigationController.navigationBar setBackgroundImage:[LMUINavigationController drawImageWithSolidColor:[UIColor redColor]] forBarMetrics:UIBarMetricsDefault];
    
    //show buttons
    self.previousButton.hidden = NO;
    self.nextButton.hidden = NO;
    
    //make some ajustments on the loaded boxes
    [self loadWhenAppear];
}

- (void) loadWhenAppear
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        int index = [self.items indexOfObject:self.filename];
        self.title = [NSString stringWithFormat:@"%d of %d", index, self.items.count];
        
        //check if boxes not saved on the server
        NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];
        if (dictnum.intValue == 0) [self.sendButton setEnabled:NO];
        
        //load image
        NSString *imagePath = [[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:self.filename];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
        self.imageView.image = image;
        self.tagView.frame = [self getImageFrameFromImageView:self.imageView];
        
        //load boxes
        NSString *boxesPath = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:self.filename];
        NSMutableArray *boxes = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:boxesPath]];
        [self.tagView.boxes setArray:boxes];
        
        [self selectedAnObject:NO];
        if (self.tagView.boxes.count > 0)
            [self.labelsView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        
        //set the box dimensions for the current context
        for(Box* box in self.tagView.boxes)
            [box setBoxDimensionsForImageSize:self.tagView.frame.size];
        
        [self.tagView setNeedsDisplay];
        keyboardVisible = NO;
    });
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [self loadWhenDisappear];
    
    if (!self.tagView.userInteractionEnabled){
        self.tagView.userInteractionEnabled = YES;
        self.scrollView.frame = CGRectMake(0 , 0, self.view.frame.size.width, self.view.frame.size.height-self.bottomToolbar.frame.size.height);
        [self.label resignFirstResponder];
    }
    
    self.labelsView.hidden = YES;
    self.labelsButton.selected = NO;
    if (![self.sendingView isHidden]) self.sendingView.hidden = YES;
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.tagView setLINEWIDTH:1.0];
    [self.imageView setImage:nil];
    self.label.hidden = YES;
    [self.tagView.boxes removeAllObjects];
    
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadWhenDisappear
{
    //save thumbnail and dictionary
    [self saveThumbnail];
    [self saveDictionary];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadTableForFilename:self.filename];
    });
}

#pragma mark -
#pragma mark UIScrollView delegate: Scrolling Images

//- (void)loadScrollViewWithImageIndex:(int) index
//{
//    
//    if(index >= self.items.count) return;
//    
//    NSString *filename = [self.items objectAtIndex:index];
//
//    //look for the view in the array. If it is not there, save it
//    UIView *composeViewSelected = [self.composeViewsArray objectAtIndex:index];
//    if ((NSNull *)composeViewSelected == [NSNull null]){
//        
//        //boxes
//        NSString *boxesPath = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
//        NSMutableArray *boxes = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:boxesPath]];
//        
//        //image
//        NSString *imagePath = [[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:filename];
//        UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
//        
//        //init views
//        composeViewSelected = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
//        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
//        imageView.tag = 200;
//        imageView.contentMode = UIViewContentModeScaleAspectFit;
//        imageView.image = image;
//        
//        TagView *annotationView = [[TagView alloc] initWithFrame:[self getImageFrameFromImageView:imageView]];
//        annotationView.tag = 100;
//        [annotationView.objects setArray:boxes];
//        annotationView.delegate = self;
//        annotationView.filename = filename;
//        for(Box* box in boxes){
//            CGFloat frameWidth = annotationView.frame.size.width;
//            CGFloat frameHeight = annotationView.frame.size.height;
//            
//            box.upperLeft = CGPointMake(box.upperLeft.x*frameWidth/box->RIGHTBOUND, box.upperLeft.y*frameHeight/box->LOWERBOUND);
//            box.lowerRight = CGPointMake(box.lowerRight.x*frameWidth/box->RIGHTBOUND, box.lowerRight.y*frameHeight/box->LOWERBOUND);
//            box->RIGHTBOUND = frameWidth;
//            box->LOWERBOUND = frameHeight;
//        }
//        [composeViewSelected addSubview:imageView];
//        [composeViewSelected addSubview:annotationView];
//        [self.composeViewsArray setObject:composeViewSelected atIndexedSubscript:index];
//    }
//    
//    //Add it to the scroll view (if it was not setted)
//    if(composeViewSelected.superview == nil){
//        // compose view to uiscrollview
//        CGRect frame = self.scrollView.frame;
//        frame.origin.x = (frame.size.width * index);
//        frame.origin.y = 0;
//        composeViewSelected.frame = frame;
//        
//        [self.scrollView addSubview:composeViewSelected];
//    }
//}

//// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    
//    // switch the indicator when more than 50% of the previous/next page is visible
//    CGFloat pageWidth = CGRectGetWidth(self.scrollView.frame);
//    self.currentScrollIndex = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
//    self.filename = [self.items objectAtIndex:self.currentScrollIndex];
////    UIView *selectedComposeView = [self.composeViewsArray objectAtIndex:self.currentScrollIndex];
////    TagView *annotationView = (TagView *)[selectedComposeView viewWithTag:100];
////    UIImageView *imageView = (UIImageView *)[selectedComposeView viewWithTag:200];
////    self.composeView = selectedComposeView;
////    self.imageView = imageView;
////    self.annotationView = annotationView;
//    NSLog(@"decelerating on page %d with filename %@", self.currentScrollIndex, self.filename);
//    
//    
//    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
//    [self loadScrollViewWithImageIndex:self.currentScrollIndex - 1];
//    [self loadScrollViewWithImageIndex:self.currentScrollIndex];
//    [self loadScrollViewWithImageIndex:self.currentScrollIndex + 1];
//}

#pragma mark -
#pragma mark UIScrollView delegate: Zoom

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView
{
    return self.composeView;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    self.previousButton.hidden = NO;
    self.nextButton.hidden = NO;
    
    if (scrollView.zoomScale > 1.0) {
        self.nextButton.hidden = YES;
        self.previousButton.hidden = YES;
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self.tagView setLINEWIDTH:scale];
}

#pragma mark -
#pragma mark Keyboard Notifications

- (void) keyboardDidShow:(NSNotification *)notif
{
    self.tagView.userInteractionEnabled = NO;
    [self.scrollView setScrollEnabled:YES];
    [self.labelsView setHidden:YES];
    [self.labelsButton setSelected:NO];
	if (keyboardVisible) return;
	
	// Get the origin of the keyboard when it finishes animating
	NSDictionary *info = [notif userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	// Get the top of the keyboard in view's coordinate system. 
	// We need to set the bottom of the scrollview to line up with it

	CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
	CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect viewFrame = self.scrollView.frame;
	viewFrame.size.height = keyboardTop;

	self.scrollView.frame = viewFrame;

    [self.scrollView scrollRectToVisible:self.label.frame animated:YES];
	keyboardVisible = YES;
}

- (void) keyboardDidHide:(NSNotification *)notif
{
    [self.scrollView setScrollEnabled:NO];

	if (!keyboardVisible)
		return;
	
    self.scrollView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height-self.bottomToolbar.frame.size.height);

	keyboardVisible = NO;
    self.tagView.userInteractionEnabled=YES;
}


#pragma mark -
#pragma mark IBAction 

-(IBAction)addAction:(id)sender
{
 
    if (![self.tip isHidden])[self.tip setHidden:YES];
    
    //get the current visible area
    CGRect visibleRect = [self.scrollView convertRect:self.scrollView.bounds toView:self.composeView];
    
    Box *box = [[Box alloc] initWithPoints:CGPointMake(visibleRect.origin.x+(self.tagView.frame.size.width  - 100)/(2*self.scrollView.zoomScale),
                                                      visibleRect.origin.y+(self.tagView.frame.size.height  - 100)/(2*self.scrollView.zoomScale)) :CGPointMake(visibleRect.origin.x+(self.tagView.frame.size.width  + 100)/(2*self.scrollView.zoomScale),visibleRect.origin.y+(self.tagView.frame.size.height  + 100)/(2*self.scrollView.zoomScale))];
    
    int num = self.tagView.boxes.count;
    [box setBounds:self.tagView.frame];
    box.color=[[self.tagView colorArray] objectAtIndex:(num%8)];
    [self.tagView.boxes addObject:box];
    [self.tagView setSelectedBox:num];

    //show the label
    NSLog(@"tagview frame: %@", NSStringFromCGRect(self.tagView.frame));
    NSLog(@"scrollview frame: %@", NSStringFromCGRect(self.scrollView.frame));
    NSLog(@"visiblerect: %@", NSStringFromCGRect(visibleRect));
    NSLog(@"");
    
    [self.label fitForBox:box onTagViewFrame:self.tagView.frame andScale:self.scrollView.zoomScale];
    
    self.label.text = @"";
    self.label.hidden = NO;
    [self.tagView setNeedsDisplay];

    if (!self.labelsView.hidden) {
        [self.labelsView setHidden:YES];
        [self.labelsButton setSelected:NO];
    }
    
    //TODO: refactor userDictionary and the way
    //Update the number of boxes to be send
    NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];
    if (dictnum.intValue < 0){
        NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue - 1];
        [self.userDictionary removeObjectForKey:self.filename];
        [self.userDictionary setObject:newdictnum forKey:self.filename];
    
    }else{
        NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue + 1];
        [self.userDictionary removeObjectForKey:self.filename];
        [self.userDictionary setObject:newdictnum forKey:self.filename];
    }

    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    [self selectedAnObject:YES];
}

- (IBAction)hideKeyboardAction:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)labelFinish:(id)sender
{
    int selected = [self.tagView SelectedBox];
    self.label.text = [self.label.text replaceByUnderscore];
    Box *box = [self.tagView.boxes objectAtIndex:selected];
    if (![box.label isEqualToString:self.label.text]) { //update the name

        box.label = self.label.text;
        [box.label replaceByUnderscore];
        
        //put the boxes corresponding to the same object with the same color
        if (![self.label.text isEqualToString:@""]) {
            for (int i=0; i<self.tagView.boxes.count; i++) {
                if (i==selected)
                    continue;
                Box *oldBox = [self.tagView.boxes objectAtIndex:i];
                if ([box.label isEqualToString:oldBox.label]) {
                    box.color = oldBox.color;
                    break;
                }
            }
        }
        [self objectModified];
    }
    
    [self.tagView setNeedsDisplay];
}


-(IBAction)doneAction:(id)sender
{
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self saveThumbnail];
    [self saveDictionary];
    [self.imageView setImage:nil];
    [self dismissViewControllerAnimated:NO completion:NULL];
}

-(IBAction)sendAction:(id)sender
{
    //save state
    [self saveDictionary];
    [self saveThumbnail];
    
    [self barButtonsEnabled:NO];
    
    //sending view
    [self.sendingView setHidden:NO];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator startAnimating];
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.tagView setLINEWIDTH:1.0];
    [self sendPhoto];
}

-(IBAction)labelAction:(id)sender
{    
    //self.navigationItem.rightBarButtonItems = nil;
    
    /*UIBarButtonItem *labelBar = [[UIBarButtonItem alloc] initWithCustomView:self.label];
    self.navigationItem.rightBarButtonItem =labelBar;*/
}

-(IBAction)deleteAction:(id)sender
{
    if(([self.tagView SelectedBox]!=-1)&&(!keyboardVisible)){
        UIActionSheet *actionSheet = [[UIActionSheet alloc]  initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Object" otherButtonTitles:nil, nil];
        actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
        [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
    }
}

-(IBAction)listAction:(id)sender
{
    [self.labelsView reloadData];
    if (self.labelsView.hidden) {
        
        //make buttons disappear
        self.previousButton.hidden = YES;
        self.nextButton.hidden = YES;
    
        if (self.tagView.boxes.count == 0) {
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x,
                                                 self.scrollView.frame.size.height-0.19375*self.view.frame.size.width+self.scrollView.contentOffset.y,
                                                 self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,
                                                 0.19375*self.view.frame.size.width)];
            
        }else if (self.tagView.boxes.count*self.labelsView.rowHeight >= self.scrollView.frame.size.height/3) {
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x,
                                                 2*self.scrollView.frame.size.height/3-0.078125*self.view.frame.size.width+self.scrollView.contentOffset.y,
                                                 self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,
                                                 self.scrollView.frame.size.height/3+0.0625*self.view.frame.size.width)];
            
        }else [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width + self.scrollView.contentOffset.x,
                                                 self.scrollView.frame.size.height - self.tagView.boxes.count*self.labelsView.rowHeight-0.078125*self.view.frame.size.width + self.scrollView.contentOffset.y,
                                                 self.scrollView.frame.size.width - 0.03125*self.view.frame.size.width,
                                                 self.tagView.boxes.count*self.labelsView.rowHeight+0.0625*self.view.frame.size.width+5)];
        self.labelsView.layer.masksToBounds = YES;
        [self.labelsView.layer setCornerRadius:10];
        
    }else{
        self.previousButton.hidden = NO;
        self.nextButton.hidden = NO;
    }
    
    [self.labelsButton setSelected:!self.labelsButton.selected];
    [self.labelsView setHidden:!self.labelsView.hidden];
    
}

-(IBAction)hideTip:(id)sender
{
    [self.tip setHidden:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Disallow recognition of tap gestures in the segmented control.
    if ([self.tagView SelectedBox] != -1)
        return NO;
    else return YES;
}

- (IBAction)changeImageAction:(id)sender
{
    
    [self loadWhenDisappear];
    
    UIButton *button = (UIButton *)sender;
    
    //select next/previous image filename
    int increase = 2*button.tag - 3;
    int currentIndex = [self.items indexOfObject:self.filename];
    int total = self.items.count;
    int a = currentIndex + increase;
    int nextIndex = (a >= 0) ? (a % total) : ((a % total) + total);
    NSString *newFilename = (NSString *)[self.items objectAtIndex:nextIndex];
    //NSLog(@"current index: %d, next index: %d, increase: %d, button.tag: %d",currentIndex, (currentIndex+increase)%self.items.count, increase, button.tag);
    
    //load new boxes and new image
    self.filename = newFilename;
    [self loadWhenAppear];
}


#pragma mark -
#pragma mark ActionSheetDelegate Methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (buttonIndex==0) {
        int num=[[self.tagView boxes] count];

        if((num<1)||([self.tagView SelectedBox]==-1))
            return;

        NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];
        if (dictnum.intValue < 0){
            if (![[[self.tagView boxes] objectAtIndex:[self.tagView SelectedBox] ] sent]) {
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
                [self.userDictionary removeObjectForKey:self.filename];
                [self.userDictionary setObject:newdictnum forKey:self.filename];
            }
           
        }
        else if(dictnum.intValue >= 0){

            if (![[[self.tagView boxes] objectAtIndex:[self.tagView SelectedBox] ] sent]) {
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue-1];

                [self.userDictionary removeObjectForKey:self.filename];
                [self.userDictionary setObject:newdictnum forKey:self.filename];

            }else{
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
                
                [self.userDictionary removeObjectForKey:self.filename];
                [self.userDictionary setObject:newdictnum forKey:self.filename];
            }
        }
    
        [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];

        [self.tagView.boxes removeObjectAtIndex:[self.tagView SelectedBox]];
        [self.tagView setSelectedBox:-1];
        self.label.hidden=YES;
        [self saveThumbnail];
        [self saveDictionary];
        [self.tagView setNeedsDisplay];
        [self selectedAnObject:NO];
    }
}

#pragma mark -
#pragma mark Buttons Management

-(void)barButtonsEnabled:(BOOL)value
{
    [self.addButton setEnabled:value];
    [self.sendButton setEnabled:value];
    [self.labelsButton setEnabled:value];
    [self.deleteButton setEnabled:value];
    [self.navigationItem setHidesBackButton:!value];
}

-(void)sendPhoto
{
    NSNumber *num = [self.userDictionary objectForKey:self.filename];
    CGPoint point = CGPointMake(self.imageView.image.size.width/self.tagView.frame.size.width, self.imageView.image.size.height/self.tagView.frame.size.height);
    
    if (num.intValue<0) [sConnection sendPhoto:self.imageView.image filename:self.filename path:[self.paths objectAtIndex:OBJECTS] withSize:point andAnnotation:self.tagView.boxes];
    else [sConnection updateAnnotationFrom:self.filename withSize:point :self.tagView.boxes];
}


#pragma mark -
#pragma mark Save State

-(void) saveThumbnail
{
    [self.tagView setSelectedBox:-1];
    [self.tagView setNeedsDisplay];
    
    UIGraphicsBeginImageContext(self.tagView.frame.size);
    [self.composeView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRef imageRef = CGImageCreateWithImageInRect(viewImage.CGImage, self.tagView.frame);
    UIImage *thumbnailImage;
    
    int thumbnailSize = 300;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) thumbnailSize = 128;
    thumbnailImage  = [[UIImage imageWithCGImage:imageRef scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:thumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationLow];
    
    //    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    //       thumbnailImage  = [[UIImage imageWithCGImage:image scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationLow];
    //
    //    else thumbnailImage  = [[UIImage imageWithCGImage:image scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationLow];
    
    CGImageRelease(imageRef);
    
    dispatch_queue_t saveQueue = dispatch_queue_create("saveQueue", NULL);
    dispatch_sync(saveQueue, ^{
        NSData *thumImage = UIImageJPEGRepresentation(thumbnailImage, 0.75);
        [[NSFileManager defaultManager] createFileAtPath:[[self.paths objectAtIndex:THUMB] stringByAppendingPathComponent:self.filename] contents:thumImage attributes:nil];
    });
    dispatch_release(saveQueue);
}

-(void)saveDictionary
{

    dispatch_queue_t saveQueue = dispatch_queue_create("saveQueue", NULL);
    dispatch_sync(saveQueue, ^{
        NSString *pathObject = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:self.filename];
        [NSKeyedArchiver archiveRootObject:self.tagView.boxes toFile:pathObject];
    });
    dispatch_release(saveQueue);
}


#pragma mark -
#pragma mark TagViewDelegate Methods

-(void)objectModified
{   
    if ([self.tagView SelectedBox] == -1)
        return;

    if ([[self.tagView.boxes objectAtIndex:[self.tagView SelectedBox]] sent]) {
        [[self.tagView.boxes objectAtIndex:[self.tagView SelectedBox]] setSent:NO];
        NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];

        if (dictnum.intValue < 0){
            NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue-1];
            [self.userDictionary removeObjectForKey:self.filename];
            [self.userDictionary setObject:newdictnum forKey:self.filename];

        }else{
            NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
            [self.userDictionary removeObjectForKey:self.filename];
            [self.userDictionary setObject:newdictnum forKey:self.filename];
        }
        
        [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
        [self.sendButton setEnabled:YES];
    }
    
    [self saveDictionary];
}

-(void)stringLabel:(NSString *)string
{
    [self.label setText:string];
}

-(void)hiddenTextField:(BOOL)value
{
    [self.label setHidden:value];
}

-(void)correctOrientationForBox:(Box *)box SuperviewFrame:(CGRect)viewSize
{    
    [self.label fitForBox:box onTagViewFrame:self.tagView.frame andScale:self.scrollView.zoomScale];
}

-(void)selectedAnObject:(BOOL)value
{    
    int dictnum  = [[self.userDictionary objectForKey:self.filename] intValue];
    self.deleteButton.enabled = value;
    self.scrollView.scrollEnabled = !value;
    self.sendButton.enabled = dictnum!=0 ?  YES : NO;
    
    [self.labelsView reloadData];
}


#pragma mark -
#pragma mark TableViewDelegate&Datasource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return self.tagView.boxes.count;
    else return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) return [NSString stringWithFormat:@"%d objects",self.tagView.boxes.count];
    else return  @"";
}


-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
    if (sectionTitle == nil) return nil;
    
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0,6,tableView.frame.size.width , 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.shadowColor = [UIColor grayColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.text = sectionTitle;
    [label setTextAlignment:NSTextAlignmentCenter];
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 42)];
    [view addSubview:label];
    
    return view;
}


- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
     static NSString *CellIdentifier = @"Cell";
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
     if (cell == nil)
         cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

    [cell setBackgroundColor:[UIColor clearColor]];
    Box *b = [self.tagView.boxes objectAtIndex:indexPath.row];
    if (b.label.length != 0) {
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:b.label];
            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, b.label.length)];
            [attrString addAttribute:NSStrokeColorAttributeName value:b.color range:NSMakeRange(0, b.label.length)];
            [attrString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-1.75] range:NSMakeRange(0, b.label.length)];

            cell.textLabel.attributedText = attrString;
            
        }else [cell.textLabel setText:b.label];
        
    }else{
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@"(No Label)"];

            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0,10)];
            [attrString addAttribute:NSStrokeColorAttributeName value:b.color range:NSMakeRange(0, 10)];
            [attrString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-1.75] range:NSMakeRange(0, 10)];
            
            cell.textLabel.attributedText = attrString;
            
        }else [cell.textLabel setText:@"(No Label)"];
        
    }
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d x %d",(int)((b.lowerRight.x - b.upperLeft.x)*self.imageView.image.size.width/self.tagView.frame.size.width),(int)((b.lowerRight.y - b.upperLeft.y)*self.imageView.image.size.height/self.tagView.frame.size.height)]];
    if (indexPath.row == [self.tagView SelectedBox])
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    else [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tagView setSelectedBox:indexPath.row];
    [self.tagView setNeedsDisplay];
    [self.labelsView reloadData];
    [self listAction:self.labelsButton];
    Box *box = [self.tagView.boxes objectAtIndex:indexPath.row];
    [self.scrollView zoomToRect:CGRectMake(box.upperLeft.x+self.tagView.frame.origin.x-10, box.upperLeft.y+self.tagView.frame.origin.y-10, box.lowerRight.x - box.upperLeft.x+20, box.lowerRight.y - box.upperLeft.y+20) animated:YES];
    [self.tagView setLINEWIDTH:self.scrollView.zoomScale];
    [self selectedAnObject:YES];
    [self correctOrientationForBox:box SuperviewFrame:self.tagView.frame];
}


#pragma mark -
#pragma mark Sending View Delegate


-(void)cancel
{
    [sConnection cancelRequestFor:0];
    [self.navigationItem setHidesBackButton:NO];
    [self.sendingView setHidden:YES];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator stopAnimating];
    [self barButtonsEnabled:YES];
    [self.deleteButton setEnabled:NO];
}

#pragma mark -
#pragma mark Rotation

- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //reload image and how it is displayed
    [self loadWhenAppear];
    
    //deselect boxes (avoid problems with self.label)
    [self.tagView setSelectedBox:-1];
    [self.tagView setNeedsDisplay];
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


#pragma mark -
#pragma mark ServerConnectionDelegate Methods

-(void)sendingProgress:(float)prog
{
    [self.sendingView.progressView setProgress:prog];
}

-(void)sendPhotoError
{
    [self errorWithTitle:@"This image could not be sent" andDescription:@"Please, try again."];
    [self barButtonsEnabled:YES];
    [self.sendingView setHidden:YES];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator stopAnimating];
}

-(void)photoSentCorrectly:(NSString *)filename
{
    if ([self.filename isEqualToString:filename]) {
        for (int i=0; i<[self.tagView.boxes count ]; i++)
            [[self.tagView.boxes objectAtIndex:i ] setSent:YES];

        [self saveDictionary];
        
    }else{
        NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
        for (int i=0; i<objects.count; i++)
            [[objects objectAtIndex:i] setSent:YES];
        
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    }
    
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:0];
    
    [self.navigationItem setHidesBackButton:NO];

        [self.sendingView setHidden:YES];
        [self.sendingView.progressView setProgress:0];
        [self.sendingView.activityIndicator stopAnimating];
    
    [self barButtonsEnabled:YES];
    [self.sendButton setEnabled:NO];
    [self.deleteButton setEnabled:NO];

    [self.userDictionary removeObjectForKey:filename];
    [self.userDictionary setObject:newdictnum forKey:filename];
    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
}

-(void)photoNotOnServer:(NSString *)filename
{
    
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    if (objects != nil) {
        for (int i=0; i<objects.count; i++)
            [[objects objectAtIndex:i] setSent:NO];
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    }
    
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:-objects.count-1];
    [self.userDictionary removeObjectForKey:filename];
    [self.userDictionary setObject:newdictnum forKey:filename];
    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    [self sendAction:self.sendButton];
}

#pragma mark -
#pragma mark Private methods

- (CGRect) getImageFrameFromImageView: (UIImageView *)iv
{
    CGSize imageSize = iv.image.size;
    CGFloat imageScale = fminf(CGRectGetWidth(iv.bounds)/imageSize.width, CGRectGetHeight(iv.bounds)/imageSize.height);
    CGSize scaledImageSize = CGSizeMake(imageSize.width*imageScale, imageSize.height*imageScale);
    CGRect imageFrame = CGRectMake(floorf(0.5f*(CGRectGetWidth(iv.bounds)-scaledImageSize.width)), floorf(0.5f*(CGRectGetHeight(iv.bounds)-scaledImageSize.height)), scaledImageSize.width, scaledImageSize.height);
    
    return imageFrame;
}

- (void)viewDidUnload {
    [self setLabelsButtonItem:nil];
    [super viewDidUnload];
}


@end
