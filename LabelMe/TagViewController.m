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
        self.username = [[NSString alloc] init];
        self.filename = [[NSString alloc] init];
        
        self.composeView = [[UIView alloc] initWithFrame:CGRectZero];
        self.annotationView = [[TagView alloc] initWithFrame:CGRectZero];
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        
        self.labelsView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];

        sConnection = [[ServerConnection alloc] init];
        sConnection.delegate = self;
    }
    return self;
}


- (void)viewDidLoad
{

    [super viewDidLoad];
    self.title = @"Annotation Tool";
    UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"];
    [self.navigationController.navigationBar setBackgroundImage:barImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    //bottom toolbar
    [self.bottomToolbar setBarStyle:UIBarStyleBlackOpaque];
    
    UIButton *addButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [addButtonView setImage:[UIImage imageNamed:@"newLabel.png"] forState:UIControlStateNormal];
    [addButtonView addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    self.addButton = [[UIBarButtonItem alloc] initWithCustomView:addButtonView];
    
    UIButton *deleteButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [deleteButtonView setImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    [deleteButtonView addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    self.deleteButton = [[UIBarButtonItem alloc] initWithCustomView:deleteButtonView];
    [self.deleteButton setEnabled:NO];
    [self.deleteButton setStyle:UIBarButtonItemStyleBordered];
    
    UIButton *sendButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,self.bottomToolbar.frame.size.height)];
    [sendButtonView setImage:[UIImage imageNamed:@"send.png"] forState:UIControlStateNormal];
    [sendButtonView addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton = [[UIBarButtonItem alloc] initWithCustomView:sendButtonView];

    self.labelsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,self.bottomToolbar.frame.size.height)];
    [self.labelsButton setImage:[UIImage imageNamed:@"labelsList.png"] forState:UIControlStateNormal];
    [self.labelsButton setImage:[UIImage imageNamed:@"labelsList-white.png"] forState:UIControlStateSelected];
    [self.labelsButton addTarget:self action:@selector(listAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *labelsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.labelsButton];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.bottomToolbar setItems:[NSArray arrayWithObjects:self.addButton,flexibleSpace,self.deleteButton,flexibleSpace, self.sendButton,flexibleSpace, labelsButtonItem, nil]];
    
    //Scroll view
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
	[self.scrollView setCanCancelContentTouches:NO];
	self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
	self.scrollView.clipsToBounds = YES;		
	self.scrollView.scrollEnabled = YES;
	self.scrollView.pagingEnabled = NO;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.delegate = self;
//    CGSize contentSize = CGSizeMake(self.scrollView.frame.size.width*self.items.count, self.scrollView.frame.size.height);
//    [self.scrollView setContentSize:contentSize];
    
    //labels
    [self.label setBorderStyle:UITextBorderStyleNone];
    [self.label setKeyboardAppearance:UIKeyboardAppearanceAlert];
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
    if ((self.items.count>1) || (self.annotationView.objects.count != 0))
        self.tip.hidden = YES;

    //sending view
    self.sendingView = [[SendingView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
    [self.sendingView setHidden:YES];
    self.sendingView.textView.text = @"Uploading to the server...";
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.sendingView.delegate = self;

    //model
    self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.frame = self.scrollView.frame;

    //compose view
    self.composeView.frame = self.scrollView.frame;
    [self.composeView addSubview:self.imageView];
    [self.composeView addSubview:self.annotationView];
    
    //annotation view
    self.annotationView.delegate = self;

    //Next and previous buttons
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.frame = CGRectMake(self.scrollView.frame.size.width - 50, self.scrollView.frame.size.height/2, 50, 50);
    [self.nextButton setImage:[UIImage imageNamed:@"next_button.png"] forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(changeImageAction:) forControlEvents:UIControlEventTouchUpInside];
    self.nextButton.tag = 2;
    
    self.previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.previousButton.frame  = CGRectMake(0, self.scrollView.frame.size.height/2, 50, 50);
    [self.previousButton setImage:[UIImage imageNamed:@"next_button.png"] forState:UIControlStateNormal];
    [self.previousButton addTarget:self action:@selector(changeImageAction:) forControlEvents:UIControlEventTouchUpInside];
    self.previousButton.tag = 1;

    
    //subview hierarchy
    [self.scrollView setContentSize:self.scrollView.frame.size];
    [self.scrollView addSubview:self.composeView];
    [self.scrollView addSubview:self.label];
    [self.scrollView addSubview:self.labelsView];
    [self.scrollView addSubview:self.tip];
    [self.scrollView addSubview:self.nextButton];
    [self.scrollView addSubview:self.previousButton];
    [self.scrollView addSubview:self.sendingView];
    

//    //Swipe gesture recognizer: for both directions the same target
//    UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
//    [swipeLeftRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
//    [swipeRightRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
//    [self.scrollView addGestureRecognizer:swipeLeftRecognizer];
//    [self.scrollView addGestureRecognizer:swipeRightRecognizer];
//    swipeLeftRecognizer.delegate = self;
//    swipeRightRecognizer.delegate = self;
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
    //check if boxes not saved on the server
    NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];
    if (dictnum.intValue == 0) [self.sendButton setEnabled:NO];
    
    //load image
    NSString *imagePath = [[self.paths objectAtIndex:IMAGES] stringByAppendingPathComponent:self.filename];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    self.imageView.image = image;
    self.annotationView.frame = [self getImageFrameFromImageView:self.imageView];
    
    //load boxes
    NSString *boxesPath = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:self.filename];
    NSMutableArray *boxes = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:boxesPath]];
    [self.annotationView.objects setArray:boxes];
    
    [self selectedAnObject:NO];
    if (self.annotationView.objects.count > 0)
        [self.labelsView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    //check for all the boxes have the correct size (correction for the downloaded boxes)
    for(Box* box in self.annotationView.objects){
        CGFloat frameWidth = self.annotationView.frame.size.width;
        CGFloat frameHeight = self.annotationView.frame.size.height;
        
        box.upperLeft = CGPointMake(box.upperLeft.x*frameWidth/box->RIGHTBOUND, box.upperLeft.y*frameHeight/box->LOWERBOUND);
        box.lowerRight = CGPointMake(box.lowerRight.x*frameWidth/box->RIGHTBOUND, box.lowerRight.y*frameHeight/box->LOWERBOUND);
        box->RIGHTBOUND = frameWidth;
        box->LOWERBOUND = frameHeight;
    }
    
    [self.annotationView setNeedsDisplay];
	keyboardVisible = NO;
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [self loadWhenDisappear];
    
    if (!self.annotationView.userInteractionEnabled){
        self.annotationView.userInteractionEnabled = YES;
        self.scrollView.frame = CGRectMake(0 , 0, self.view.frame.size.width, self.view.frame.size.height-self.bottomToolbar.frame.size.height);
        [self.label resignFirstResponder];
    }
    
    self.labelsView.hidden = YES;
    self.labelsButton.selected = NO;
    if (![self.sendingView isHidden]) self.sendingView.hidden = YES;
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.annotationView setLINEWIDTH:1.0];
    [self.imageView setImage:nil];
    self.label.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadWhenDisappear
{
    //save thumbnail and dictionary
    [self saveThumbnail];
    [self saveDictionary];
    [self.delegate reloadTableOnImageGallery];
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
    //calculate the visible frame for when adding a new box being adapted to the box
    if (scrollView.zoomScale > 1.0) {
        
        //disable buttons
        self.nextButton.hidden = YES;
        self.previousButton.hidden = YES;
        
        CGPoint point = self.annotationView.frame.origin; // origin
        CGPoint point2 = CGPointMake(0, 0); // size
        
        if (scrollView.contentOffset.y < self.annotationView.frame.origin.y*scrollView.zoomScale) {
            
            point.y = scrollView.contentOffset.y/scrollView.zoomScale;
            point2.y += self.annotationView.frame.origin.y*scrollView.zoomScale - scrollView.contentOffset.y;
        }
        if ((scrollView.contentOffset.y + scrollView.frame.size.height-self.annotationView.frame.origin.y*scrollView.zoomScale)>(self.annotationView.frame.size.height)*scrollView.zoomScale) {
            
            point2.y += scrollView.contentOffset.y + scrollView.frame.size.height -(self.annotationView.frame.size.height + self.annotationView.frame.origin.y)*scrollView.zoomScale;
            
        }
        if (scrollView.contentOffset.x< self.annotationView.frame.origin.x*scrollView.zoomScale) {
            point.x = scrollView.contentOffset.x/scrollView.zoomScale;
            point2.x += self.annotationView.frame.origin.x*scrollView.zoomScale - scrollView.contentOffset.x;
            
            
        }
        if ((scrollView.contentOffset.x + scrollView.frame.size.width -self.annotationView.frame.size.width*scrollView.zoomScale)>(self.annotationView.frame.origin.x)*scrollView.zoomScale) {
            point2.x += scrollView.contentOffset.x + scrollView.frame.size.width -(self.annotationView.frame.size.width + self.annotationView.frame.origin.x)*scrollView.zoomScale;
            
            
        }
        CGRect rectvisible = CGRectMake(scrollView.contentOffset.x/scrollView.zoomScale - point.x, scrollView.contentOffset.y/scrollView.zoomScale - point.y, (scrollView.frame.size.width-point2.x)/scrollView.zoomScale, (scrollView.frame.size.height-point2.y)/scrollView.zoomScale);
        [self.annotationView setVisibleFrame:rectvisible];
        
    }else {
        [self.annotationView setVisibleFrame:CGRectMake(0, 0, self.annotationView.frame.size.width, self.annotationView.frame.size.height)];
        self.previousButton.hidden = NO;
        self.nextButton.hidden = NO;
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self.annotationView setLINEWIDTH:scale];
}

#pragma mark -
#pragma mark Keyboard Notifications

- (void) keyboardDidShow:(NSNotification *)notif
{
    self.annotationView.userInteractionEnabled = NO;
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
    self.annotationView.userInteractionEnabled=YES;
}


#pragma mark -
#pragma mark IBAction 

-(IBAction)addAction:(id)sender
{
 
    if (![self.tip isHidden])[self.tip setHidden:YES];
    
    Box *box = [[Box alloc]initWithPoints:CGPointMake(self.annotationView.visibleFrame.origin.x+(self.annotationView.frame.size.width  - 100)/(2*self.scrollView.zoomScale),
                                                      self.annotationView.visibleFrame.origin.y+(self.annotationView.frame.size.height  - 100)/(2*self.scrollView.zoomScale)) :CGPointMake(self.annotationView.visibleFrame.origin.x+(self.annotationView.frame.size.width  + 100)/(2*self.scrollView.zoomScale),self.annotationView.visibleFrame.origin.y+(self.annotationView.frame.size.height  + 100)/(2*self.scrollView.zoomScale))];
    
    int num = self.annotationView.objects.count;
    [box setBounds:self.annotationView.frame];
    [box generateDateString];
    box.downloadDate = [NSDate date];
    box.color=[[self.annotationView colorArray] objectAtIndex:(num%8)];
    [[self.annotationView objects] addObject:box];
    [self.annotationView setSelectedBox:num];

    [self.label setCorrectOrientationWithCorners:box.upperLeft :box.lowerRight subviewFrame:self.annotationView.frame andViewSize:self.scrollView.frame.size andScale:self.scrollView.zoomScale];
    self.label.text = @"";
    self.label.hidden = NO;
    [self.annotationView setNeedsDisplay];

    if (!self.labelsView.hidden) {
        [self.labelsView setHidden:YES];
        [self.labelsButton setSelected:NO];
    }
    

    NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];
    if (dictnum.intValue < 0){
        NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue -1];
        [self.userDictionary removeObjectForKey:self.filename];
        [self.userDictionary setObject:newdictnum forKey:self.filename];
    
    }else{
        NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
        [self.userDictionary removeObjectForKey:self.filename];
        [self.userDictionary setObject:newdictnum forKey:self.filename];
    }

    [self.userDictionary writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    [self selectedAnObject:YES];
}

- (IBAction)labelFinish:(id)sender
{
    int selected=[self.annotationView SelectedBox];
   self.label.text = [self.label.text replaceByUnderscore];
        Box *box = [[self.annotationView objects] objectAtIndex: selected];
        if (![box.label isEqualToString:self.label.text]) {
            
            box.label = self.label.text;
            [box.label replaceByUnderscore];
        
            if (![self.label.text isEqualToString:@""]) {
                for (int i=0; i<self.annotationView.objects.count; i++) {
                    if (i==selected)
                        continue;
                    Box *b=[[self.annotationView objects] objectAtIndex: i];
                    if ([box.label isEqualToString:b.label]) {
                        box.color = b.color;
                        break;
                    }
                }
            }
            [self objectModified];
        }
    [self.annotationView setNeedsDisplay];
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
    [self.annotationView setLINEWIDTH:1.0];
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
    if(([self.annotationView SelectedBox]!=-1)&&(!keyboardVisible)){
        UIActionSheet *actionSheet = [[UIActionSheet alloc]  initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Object" otherButtonTitles:nil, nil];
        actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
        [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
    }
}

-(IBAction)listAction:(id)sender
{
    [self.labelsView reloadData];
    if (self.labelsView.hidden) {
    
        if (self.annotationView.objects.count == 0) {
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x,
                                                 self.scrollView.frame.size.height-0.19375*self.view.frame.size.width+self.scrollView.contentOffset.y,
                                                 self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,
                                                 0.19375*self.view.frame.size.width)];
            
        }else if (self.annotationView.objects.count*self.labelsView.rowHeight >= self.scrollView.frame.size.height/3) {
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x,
                                                 2*self.scrollView.frame.size.height/3-0.078125*self.view.frame.size.width+self.scrollView.contentOffset.y,
                                                 self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,
                                                 self.scrollView.frame.size.height/3+0.0625*self.view.frame.size.width)];
            
        }else [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width + self.scrollView.contentOffset.x,
                                                 self.scrollView.frame.size.height - self.annotationView.objects.count*self.labelsView.rowHeight-0.078125*self.view.frame.size.width + self.scrollView.contentOffset.y,
                                                 self.scrollView.frame.size.width - 0.03125*self.view.frame.size.width,
                                                 self.annotationView.objects.count*self.labelsView.rowHeight+0.0625*self.view.frame.size.width+5)];
        self.labelsView.layer.masksToBounds = YES;
        [self.labelsView.layer setCornerRadius:10];
        
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
    if ([self.annotationView SelectedBox] != -1)
        return NO;
    else return YES;
}

- (IBAction)changeImageAction:(id)sender
{
    
    [self loadWhenDisappear];
    
    UIButton *button = (UIButton *)sender;
    
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
        int num=[[self.annotationView objects] count];

        if((num<1)||([self.annotationView SelectedBox]==-1))
            return;

        NSNumber *dictnum  = [self.userDictionary objectForKey:self.filename];
        if (dictnum.intValue < 0){
            if (![[[self.annotationView objects] objectAtIndex:[self.annotationView SelectedBox] ] sent]) {
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
                [self.userDictionary removeObjectForKey:self.filename];
                [self.userDictionary setObject:newdictnum forKey:self.filename];
            }
           
        }
        else if(dictnum.intValue >= 0){

            if (![[[self.annotationView objects] objectAtIndex:[self.annotationView SelectedBox] ] sent]) {
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

        [self.annotationView.objects removeObjectAtIndex:[self.annotationView SelectedBox]];
        [self.annotationView setSelectedBox:-1];
        self.label.hidden=YES;
        [self saveThumbnail];
        [self saveDictionary];
        [self.annotationView setNeedsDisplay];
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
    CGPoint point = CGPointMake(self.imageView.image.size.width/self.annotationView.frame.size.width, self.imageView.image.size.height/self.annotationView.frame.size.height);
    
    if (num.intValue<0) [sConnection sendPhoto:self.imageView.image filename:self.filename path:[self.paths objectAtIndex:OBJECTS] withSize:point andAnnotation:self.annotationView.objects];
    else [sConnection updateAnnotationFrom:self.filename withSize:point :self.annotationView.objects];
}


#pragma mark -
#pragma mark Save State

-(void) saveThumbnail
{
    [self.annotationView setSelectedBox:-1];
    [self.annotationView setNeedsDisplay];
            
    UIGraphicsBeginImageContext(self.annotationView.frame.size);
    [self.composeView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRef imageRef = CGImageCreateWithImageInRect(viewImage.CGImage, self.annotationView.frame);
    UIImage *thumbnailImage;
    
    int thumbnailSize = 300;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) thumbnailSize = 128;
    thumbnailImage  = [[UIImage imageWithCGImage:imageRef scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:thumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    
    //    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    //       thumbnailImage  = [[UIImage imageWithCGImage:image scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    //
    //    else thumbnailImage  = [[UIImage imageWithCGImage:image scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    
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
        [NSKeyedArchiver archiveRootObject:self.annotationView.objects toFile:pathObject];
    });
    dispatch_release(saveQueue);
}


#pragma mark -
#pragma mark TagViewDelegate Methods

-(void)objectModified
{   
    if ([self.annotationView SelectedBox] == -1)
        return;

    if ([[self.annotationView.objects objectAtIndex:[self.annotationView SelectedBox]] sent]) {
        [[self.annotationView.objects objectAtIndex:[self.annotationView SelectedBox]] setSent:NO];
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

-(void)correctOrientation:(CGPoint)upperLeft :(CGPoint)lowerRight SuperviewFrame:(CGRect)viewSize
{
    [self.label setCorrectOrientationWithCorners:upperLeft :lowerRight subviewFrame:viewSize andViewSize:self.scrollView.frame.size andScale:self.scrollView.zoomScale];
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
    if (section == 0) return self.annotationView.objects.count;
    else return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) return [NSString stringWithFormat:@"%d objects",self.annotationView.objects.count];
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
    Box *b = [self.annotationView.objects objectAtIndex:indexPath.row];
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
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d x %d",(int)((b.lowerRight.x - b.upperLeft.x)*self.imageView.image.size.width/self.annotationView.frame.size.width),(int)((b.lowerRight.y - b.upperLeft.y)*self.imageView.image.size.height/self.annotationView.frame.size.height)]];
    if (indexPath.row == [self.annotationView SelectedBox])
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    else [cell setAccessoryType:UITableViewCellAccessoryNone];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.annotationView setSelectedBox:indexPath.row];
    [self.annotationView setNeedsDisplay];
    [self.labelsView reloadData];
    [self listAction:self.labelsButton];
    Box *box = [self.annotationView.objects objectAtIndex:indexPath.row];
    [self.scrollView zoomToRect:CGRectMake(box.upperLeft.x+self.annotationView.frame.origin.x-10, box.upperLeft.y+self.annotationView.frame.origin.y-10, box.lowerRight.x - box.upperLeft.x+20, box.lowerRight.y - box.upperLeft.y+20) animated:YES];
    [self.annotationView setLINEWIDTH:self.scrollView.zoomScale];
    [self selectedAnObject:YES];
    [self correctOrientation:box.upperLeft :box.lowerRight SuperviewFrame:self.annotationView.frame];
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
        for (int i=0; i<[self.annotationView.objects count ]; i++)
            [[self.annotationView.objects objectAtIndex:i ] setSent:YES];

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
    [super viewDidUnload];
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
