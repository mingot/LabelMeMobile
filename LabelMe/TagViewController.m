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


@implementation TagViewController

@synthesize  scrollView = _scrollView;
@synthesize label = _label;
@synthesize addButton = _addButton;
@synthesize deleteButton = _deleteButton;
@synthesize sendButton = _sendButton;
@synthesize imageView = _imageView;
@synthesize filename = _filename;
@synthesize paths = _paths;
@synthesize annotationView = _annotationView;
@synthesize username = _username;
@synthesize composeView = _composeView;
@synthesize labelsButton = _labelsButton;
@synthesize bottomToolbar = _bottomToolbar;
@synthesize labelsView = _labelsView;
@synthesize sendingView = _sendingView;

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.username = [[NSString alloc] init];
        self.filename = [[NSString alloc] init];
        self.annotationView = [[TagView alloc] initWithFrame:CGRectZero];
        self.composeView = [[UIView alloc] initWithFrame:CGRectZero];
        self.labelsView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];

        sConnection = [[ServerConnection alloc] init];
        sConnection.delegate = self;
    }
    return self;
}


#pragma mark -
#pragma mark  View lifecycle

- (void)viewDidLoad
{

    [super viewDidLoad];

    UIImage *titleImage = [UIImage imageNamed:@"logo-title.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    titleView.image = titleImage;
    self.navigationItem.titleView = titleView;

    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    self.title = @"Annotation Tool";

    //bottom toolbar
    [self.bottomToolbar setBarStyle:UIBarStyleBlackOpaque];
    UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"] ;
    UIButton *addButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [addButtonView setImage:[UIImage imageNamed:@"newLabel.png"] forState:UIControlStateNormal];
    [addButtonView addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    self.addButton = [[UIBarButtonItem alloc] initWithCustomView:addButtonView];
    UIButton *deleteButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [deleteButtonView setImage:[UIImage imageNamed:@"delete.png"] forState:UIControlStateNormal];
    [deleteButtonView addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
    self.deleteButton = [[UIBarButtonItem alloc] initWithCustomView:deleteButtonView];
    [self.deleteButton setEnabled:NO];
    UIButton *sendButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [sendButtonView setImage:[UIImage imageNamed:@"send.png"] forState:UIControlStateNormal];
    [sendButtonView addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton = [[UIBarButtonItem alloc] initWithCustomView:sendButtonView];

    labelsButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [labelsButtonView setImage:[UIImage imageNamed:@"labelsList.png"] forState:UIControlStateNormal];
    [labelsButtonView setImage:[UIImage imageNamed:@"labelsList-white.png"] forState:UIControlStateSelected];

    [labelsButtonView addTarget:self action:@selector(listAction:) forControlEvents:UIControlEventTouchUpInside];
    self.labelsButton = [[UIBarButtonItem alloc] initWithCustomView:labelsButtonView];
 
    [self.navigationController.navigationBar setBackgroundImage:barImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    _flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [self.bottomToolbar setItems:[NSArray arrayWithObjects:self.addButton,_flexibleSpace,self.deleteButton,_flexibleSpace, self.sendButton,_flexibleSpace,self.labelsButton, nil]];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.label setBorderStyle:UITextBorderStyleNone];

    [self.scrollView setBackgroundColor:[UIColor blackColor]];
	[self.scrollView setCanCancelContentTouches:NO];
	self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
	self.scrollView.clipsToBounds = YES;		
	self.scrollView.scrollEnabled = YES;
	self.scrollView.pagingEnabled = NO;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.delegate = self;
    self.composeView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    // TAGVIEW INIT

    self.annotationView.delegate = self;
    [self.scrollView setContentSize:self.scrollView.frame.size];

    labelSize = self.label.frame.size;

    [self.composeView addSubview:self.imageView];
    [self.composeView addSubview:self.annotationView];
    [self.scrollView addSubview:self.label];

    [self.deleteButton setStyle:UIBarButtonItemStyleBordered];

    [self.labelsView setBackgroundColor:[UIColor clearColor]];
    UIImage *globo = [[UIImage imageNamed:@"globo4.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ];
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.scrollView.frame];
    [backgroundView setImage:globo];

    
    [self.labelsView setHidden:YES];
    [self.labelsView setDelegate:self];
    [self.labelsView setDataSource:self];
    [self.labelsView setRowHeight:30];
    [self.scrollView addSubview:self.composeView];
    
    //sending view
    self.sendingView = [[SendingView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)];
    [self.sendingView setHidden:YES];
    self.sendingView.label.text = @"Uploading to the server...";
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.sendingView.delegate = self;
    
    [self.scrollView addSubview:self.label];
    [self.scrollView addSubview:self.labelsView];
    [self.scrollView addSubview:self.sendingView];

    
    [self.label setKeyboardAppearance:UIKeyboardAppearanceAlert];

    self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];
    self.image = self.imageView.image;
    
    tip = [[UIButton alloc] initWithFrame:CGRectMake(25, 2*self.scrollView.frame.size.height/3, self.scrollView.frame.size.width/2, self.scrollView.frame.size.height/3)];
    [tip setBackgroundImage:[[UIImage imageNamed:@"globo.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ] forState:UIControlStateNormal];
    UILabel *tiplabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, tip.frame.size.width-24, tip.frame.size.height-24)];
    tiplabel.numberOfLines = 4;
    tiplabel.text = @"Tip:\nPress this button \nto add a bounding box!";
    tiplabel.textColor = [UIColor redColor];
    tiplabel.backgroundColor = [UIColor clearColor];
    
    [tip addSubview:tiplabel];
    [tip addTarget:self action:@selector(hideTip:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:tip];
    numImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.paths objectAtIndex:IMAGES]] error:NULL].count;
    if ((numImages>1) || (self.annotationView.objects.count != 0))
        tip.hidden = YES;

    [self.labelsView setBackgroundView:backgroundView];
    
}


- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self selectedAnObject:NO];

    if (self.annotationView.objects.count >0)
        [self.labelsView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        

    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *dictnum  = [dict objectForKey:self.filename];
    if (dictnum.intValue == 0)
        [self.sendButton setEnabled:NO];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
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
    
    if(self.forThumbnailUpdating) {self.forThumbnailUpdating=NO; [self.navigationController popViewControllerAnimated:NO];}
}

- (void) viewWillDisappear:(BOOL)animated
{    
	[super viewWillDisappear:animated];
    
    if (!self.annotationView.userInteractionEnabled){
        self.annotationView.userInteractionEnabled = YES;
        self.scrollView.frame = CGRectMake(0 , 0, self.view.frame.size.width, self.view.frame.size.height-self.bottomToolbar.frame.size.height);
        [self.label resignFirstResponder];
    }
    
    [self.labelsView setHidden:YES];
    [labelsButtonView setSelected:NO];
    if (![self.sendingView isHidden]) [self.sendingView setHidden:YES];
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.annotationView setLINEWIDTH:1.0];
    
    //save thumbnail and dictionary
    [self saveThumbnail];
    [self saveDictionary];
    [self.imageView setImage:nil];
    self.label.hidden=YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Tip View
-(IBAction)hideTip:(id)sender{
    [tip setHidden:YES];
}

#pragma mark -
#pragma mark Keyboard Notifications

- (void) keyboardDidShow:(NSNotification *)notif {
    self.annotationView.userInteractionEnabled=NO;
    [self.scrollView setScrollEnabled:YES];
    [self.labelsView setHidden:YES];
    [labelsButtonView setSelected:NO];
	if (keyboardVisible) {
		//NSLog(@"%@", @"Keyboard is already visible.  Ignoring notifications.");
		return;
	}
	// The keyboard wasn't visible before
	//NSLog(@"Resizing smaller for keyboard");
	
	// Get the origin of the keyboard when it finishes animating
	NSDictionary *info = [notif userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	// Get the top of the keyboard in view's coordinate system. 
	// We need to set the bottom of the scrollview to line up with it
    //NSLog(@"1.  origeny= %f; height=%f",self.scrollView.bounds.origin.y,self.scrollView.frame.size.height);

	CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
	CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect viewFrame = self.scrollView.frame;
	viewFrame.size.height = keyboardTop;

	self.scrollView.frame = viewFrame;

  //  Box *currentBox = [self.annotationView.dictionaryBox objectForKey:[NSString stringWithFormat:@"%d",[self.annotationView SelectedBox]]];
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
#pragma mark Set Image/Filename

-(void)setImage:(UIImage *)image
{

   double f = image.size.height/image.size.width;
   double f2 = self.scrollView.frame.size.height / self.scrollView.frame.size.width;
   if (f>f2) {
        [self.imageView setFrame:CGRectMake((self.scrollView.frame.size.width-self.scrollView.frame.size.height/f)/2, 0, self.scrollView.frame.size.height/f, self.scrollView.frame.size.height)];
        [self.annotationView setFrame:CGRectMake((self.scrollView.frame.size.width-self.scrollView.frame.size.height/f)/2,  0, self.scrollView.frame.size.height/f, self.scrollView.frame.size.height)];
    }else{
        [self.imageView setFrame:CGRectMake(0.0, (self.scrollView.frame.size.height-self.scrollView.frame.size.width*f)/2,self.scrollView.frame.size.width , self.scrollView.frame.size.width*f)];
        [self.annotationView setFrame:CGRectMake(0.0, (self.scrollView.frame.size.height-self.scrollView.frame.size.width*f)/2,self.scrollView.frame.size.width , self.scrollView.frame.size.width*f)];
    }
    
    [self.annotationView setVisibleFrame:CGRectMake(0, 0, self.annotationView.frame.size.width, self.annotationView.frame.size.height)];
   
    self.imageView.image = image;
    // faltaria poner el aspect size
}

-(void)createPlistEntry:(NSString *)filename
{
    [self.sendButton setTitle:@"Send"];
    NSString *plistPath = [[NSString alloc] initWithFormat:@"%@/%@.plist",[self.paths objectAtIndex:USER],self.username];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [dict setObject:[[NSNumber alloc] initWithInt:-1] forKey:filename];
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
}


-(void)createFilename
{
    NSString *date = [[NSString alloc]initWithString:[[[NSDate date] description] substringToIndex:19]];
    date = [date stringByReplacingOccurrencesOfString:@" " withString:@""];
    date = [date stringByReplacingOccurrencesOfString:@"-" withString:@""];
    date = [date stringByReplacingOccurrencesOfString:@":" withString:@""];

    self.filename = [date stringByAppendingFormat:@"%@.jpg",self.username];
}

#pragma mark -
#pragma mark IBAction Method
-(IBAction)addAction:(id)sender{

   // int num = [self.annotationView numLabels];
    int num = self.annotationView.objects.count;
    //NSLog(@"addaction: numlabels,%d",self.annotationView.numLabels);
    if (![tip isHidden]) {
        [tip setHidden:YES];
    }
    Box *box = [[Box alloc]initWithPoints:CGPointMake(self.annotationView.visibleFrame.origin.x+(self.annotationView.frame.size.width  - 100)/(2*self.scrollView.zoomScale), self.annotationView.visibleFrame.origin.y+(self.annotationView.frame.size.height  - 100)/(2*self.scrollView.zoomScale)) :CGPointMake(self.annotationView.visibleFrame.origin.x+(self.annotationView.frame.size.width  + 100)/(2*self.scrollView.zoomScale),self.annotationView.visibleFrame.origin.y+(self.annotationView.frame.size.height  + 100)/(2*self.scrollView.zoomScale))];
    [box setBounds:self.annotationView.frame];
    [box generateDateString];
    box.downloadDate = [NSDate date];
    box.color=[[self.annotationView colorArray] objectAtIndex:(num%8)];
    [[self.annotationView objects] addObject:box];
    [self.annotationView setSelectedBox:num];

    

    num++;
    //[self.annotationView setNumLabels:num];
    [self.label setCorrectOrientationWithCorners:box.upperLeft :box.lowerRight subviewFrame:self.annotationView.frame andViewSize:self.scrollView.frame.size andScale:self.scrollView.zoomScale];
    //[self.label setFrame:CGRectMake(self.label.frame.origin.x, self.label.frame.origin.y+self.scrollView.contentOffset.y, self.label.frame.size.width, self.label.frame.size.height)];
    self.label.text=@"";
    self.label.hidden=NO;
    [self.annotationView setNeedsDisplay];

    if (!self.labelsView.hidden) {
        [self.labelsView setHidden:YES];
        [labelsButtonView setSelected:NO];
    }
    //self.paths = [self newArrayWithFolders:self.username];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *dictnum  = [dict objectForKey:self.filename];
    if (dictnum.intValue < 0){
        NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue -1];
        [dict removeObjectForKey:self.filename];
        [dict setObject:newdictnum forKey:self.filename];
    }
    else{
        NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
        [dict removeObjectForKey:self.filename];
        [dict setObject:newdictnum forKey:self.filename];

    }
    

    // ya la cambia??
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    [self selectedAnObject:YES];
}

-(IBAction)labelFinish:(id)sender{
    int selected=[self.annotationView SelectedBox];
    //
   self.label.text = [self.label.text replaceByUnderscore];
        Box *box = [[self.annotationView objects] objectAtIndex: selected];
        if (![box.label isEqualToString:self.label.text]) {
            
            box.label= self.label.text;
            [box.label replaceByUnderscore];

            // [str release];
        
           if (![self.label.text isEqualToString:@""]) { 
            for (int i=0; i<self.annotationView.objects.count; i++) {
                if (i==selected) {
                    continue;
                }
                Box *b=[[self.annotationView objects] objectAtIndex: i];
                if ([box.label isEqualToString:b.label]) {
                    box.color=b.color;
                    //[self.annotationView.objects replaceObjectAtIndex:selected withObject:box];
                    break;
                }
                
            }
           }
            [self objectModified];
        }
   // }
    
    //[box release];
    
    [self.annotationView setNeedsDisplay];

    
}
-(IBAction)doneAction:(id)sender{
    //Aqui falta guardar la foto y los rectángulos.
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self saveThumbnail];
    [self saveDictionary];
    [self.imageView setImage:nil];
    [self dismissViewControllerAnimated:NO completion:NULL];
    
    //[self.annotationView setObjects:nil];
    
    
}
-(IBAction)sendAction:(id)sender{
    
    [self saveAnnotation];
    [self barButtonsEnabled:NO];
    [self.sendingView setHidden:NO];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator startAnimating];
    //[self performSelectorInBackground:@selector(sendPhoto) withObject:nil];
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self.annotationView setLINEWIDTH:1.0];
    [self sendPhoto];
    
    
}
-(IBAction)labelAction:(id)sender{
    

    //self.navigationItem.rightBarButtonItems = nil;
    
    /*UIBarButtonItem *labelBar = [[UIBarButtonItem alloc] initWithCustomView:self.label];
    self.navigationItem.rightBarButtonItem =labelBar;*/

}
-(IBAction)deleteAction:(id)sender{
    if(([self.annotationView SelectedBox]!=-1)&&(!keyboardVisible)){
        UIActionSheet *actionSheet = [[UIActionSheet alloc]  initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Object" otherButtonTitles:nil, nil];
        actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
        //[actionSheet showFromToolbar:self.bottomToolbar];
        [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
    }
   
    
    
}
-(IBAction)listAction:(id)sender
{
    
    [self.labelsView reloadData];
    if (self.labelsView.hidden) {
    
        if (self.annotationView.objects.count == 0) {
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x, self.scrollView.frame.size.height-0.19375*self.view.frame.size.width+self.scrollView.contentOffset.y, self.scrollView.frame.size.width-0.03125*self.view.frame.size.width, 0.19375*self.view.frame.size.width)];
        }
        else if (self.annotationView.objects.count*self.labelsView.rowHeight >= self.scrollView.frame.size.height/3) {
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x, 2*self.scrollView.frame.size.height/3-0.078125*self.view.frame.size.width+self.scrollView.contentOffset.y, self.scrollView.frame.size.width-0.03125*self.view.frame.size.width, self.scrollView.frame.size.height/3+0.0625*self.view.frame.size.width)];
        }
        else{
            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x, self.scrollView.frame.size.height - self.annotationView.objects.count*self.labelsView.rowHeight-0.078125*self.view.frame.size.width+self.scrollView.contentOffset.y, self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,  self.annotationView.objects.count*self.labelsView.rowHeight+0.0625*self.view.frame.size.width)];
        }
        // [self.labelsView setContentSize:CGSizeMake(self.labelsView.frame.size.width, 30+ self.annotationView.objects.count*30)];
        self.labelsView.layer.masksToBounds = YES;
        [self.labelsView.layer setCornerRadius:10];
        //  [numObjects release];
        
    }
    
    [labelsButtonView setSelected:!labelsButtonView.selected];
    [self.labelsView setHidden:!self.labelsView.hidden];
    
}

#pragma mark -
#pragma mark ActionSheetDelegate Methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{

    if (buttonIndex==0) {
        int num=[[self.annotationView objects] count];

        if((num<1)||([self.annotationView SelectedBox]==-1)){
            return;
        }

        NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
        NSNumber *dictnum  = [dict objectForKey:self.filename];
        if (dictnum.intValue < 0){
            if (![[[self.annotationView objects] objectAtIndex:[self.annotationView SelectedBox] ] sent]) {
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
                [dict removeObjectForKey:self.filename];
                [dict setObject:newdictnum forKey:self.filename];
            }
           
        }
        else if(dictnum.intValue >= 0){

            if (![[[self.annotationView objects] objectAtIndex:[self.annotationView SelectedBox] ] sent]) {
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue-1];

                [dict removeObjectForKey:self.filename];
                [dict setObject:newdictnum forKey:self.filename];

            }
            else{
                NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
                
                [dict removeObjectForKey:self.filename];
                [dict setObject:newdictnum forKey:self.filename];
                
            }

        }
        
        [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];

        [self.annotationView.objects removeObjectAtIndex:[self.annotationView SelectedBox]];
        [self.annotationView setSelectedBox:-1];
        self.label.hidden=YES;
        [self saveAnnotation];
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
    NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *num = [dict objectForKey:self.filename];
    
    CGPoint point = CGPointMake(self.imageView.image.size.width/self.annotationView.frame.size.width, self.imageView.image.size.height/self.annotationView.frame.size.height);
    
    if (num.intValue<0) [sConnection sendPhoto:self.imageView.image filename:self.filename path:[self.paths objectAtIndex:OBJECTS] withSize:point andAnnotation:self.annotationView.objects];
    else [sConnection updateAnnotationFrom:self.filename withSize:point :self.annotationView.objects];
}


#pragma mark -
#pragma mark Save State
-(BOOL) saveThumbnail
{
    [self.annotationView setSelectedBox:-1];
    [self.annotationView setNeedsDisplay];
    UIGraphicsBeginImageContext(self.scrollView.frame.size);
    [self.scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRef imageRef = CGImageCreateWithImageInRect(viewImage.CGImage, self.imageView.frame);
    UIImage *thumbnailImage = nil;
    NSLog(@"[THUMBNAIL] imagesize: %zux%zu",CGImageGetWidth(imageRef),CGImageGetHeight(imageRef));
    
    int thumbnailSize = 300;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) thumbnailSize = 128;
    thumbnailImage  = [[UIImage imageWithCGImage:imageRef scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:thumbnailSize transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//       thumbnailImage  = [[UIImage imageWithCGImage:image scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
//
//    else thumbnailImage  = [[UIImage imageWithCGImage:image scale:1.0 orientation:viewImage.imageOrientation] thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh];
    
    CGImageRelease(imageRef);
    NSData *thumImage = UIImageJPEGRepresentation(thumbnailImage, 0.75);
    if([[NSFileManager defaultManager] createFileAtPath:[[self.paths objectAtIndex:THUMB] stringByAppendingPathComponent:self.filename] contents:thumImage attributes:nil]) return YES;
    else return NO;
}


-(void)saveImage:(UIImage *)image
{
    @autoreleasepool
    {
        if (self.paths == nil)
            self.paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:self.username]];

        //set self.filename
        [self createFilename];
        [self createPlistEntry:self.filename];
        
        NSString *pathImages = [[self.paths objectAtIndex:IMAGES ] stringByAppendingPathComponent:self.filename];
        [[NSFileManager defaultManager] createFileAtPath:pathImages contents:UIImageJPEGRepresentation(image, 1.0) attributes:nil];
        NSLog(@"[IMAGE] Saved at path %@", pathImages);
        
        NSString *pathThumb = [[self.paths objectAtIndex:THUMB ] stringByAppendingPathComponent:self.filename];
        [[NSFileManager defaultManager] createFileAtPath:pathThumb contents:UIImageJPEGRepresentation([image thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil];
        NSLog(@"[THUMB] Saved at path %@", pathThumb);
        
        [self saveDictionary];
    }
}


-(BOOL)saveDictionary
{
    NSString *pathObject = [[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:self.filename ];
    if([NSKeyedArchiver archiveRootObject:self.annotationView.objects toFile:pathObject]) return YES;
    else return NO;
}


-(void)saveAnnotation
{
    [self saveThumbnail];
    [self saveDictionary];
}



#pragma mark -
#pragma mark TagViewDelegate Methods
-(void)objectModified{
   
    if ([self.annotationView SelectedBox] == -1)
        return;

    if ([[self.annotationView.objects objectAtIndex:[self.annotationView SelectedBox]] sent]) {
        [[self.annotationView.objects objectAtIndex:[self.annotationView SelectedBox]] setSent:NO];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
        NSNumber *dictnum  = [dict objectForKey:self.filename];
//        if (dictnum.intValue == -1) {
//            NSNumber *newdictnum = [[NSNumber alloc]initWithInt:-2];
//            [dict removeObjectForKey:self.filename];
//            [dict setObject:newdictnum forKey:self.filename];
//            [newdictnum release];
//        }
        if (dictnum.intValue < 0){
            NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue-1];
            [dict removeObjectForKey:self.filename];
            [dict setObject:newdictnum forKey:self.filename];

        }else{
            NSNumber *newdictnum = [[NSNumber alloc]initWithInt:dictnum.intValue+1];
            [dict removeObjectForKey:self.filename];
            [dict setObject:newdictnum forKey:self.filename];
        }
        
        // ya la cambia??
        [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
        [self.sendButton setEnabled:YES];

    }
    [self saveDictionary];
    //[self saveThumbnail];
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
    //[self.label setFrame:CGRectMake(self.label.frame.origin.x, self.label.frame.origin.y+self.scrollView.contentOffset.y, self.label.frame.size.width, self.label.frame.size.height)];
}

-(void)selectedAnObject:(BOOL)value
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    
    int dictnum  = [[dict objectForKey:self.filename] intValue];
    self.deleteButton.enabled = value;
    self.scrollView.scrollEnabled = !value;
    self.sendButton.enabled = dictnum!=0 ?  YES : NO;
    
    [self.labelsView reloadData];
}


#pragma mark -
#pragma mark ScrollViewDelegate Method
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
   /* if ( self.annotationView.SelectedBox != -1) {
        NSLog(@"scroll not enabled");
        self.scrollView.scrollEnabled = NO;
    }
    else{
        self.scrollView.scrollEnabled = YES;
    }*/
  //
    return self.composeView;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (scrollView.zoomScale > 1.0) {
        CGPoint point = self.annotationView.frame.origin; // origin
        CGPoint point2 = CGPointMake(0, 0); // size
        
        if (scrollView.contentOffset.y< self.annotationView.frame.origin.y*scrollView.zoomScale) {
           
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
    }
    else{
        [self.annotationView setVisibleFrame:CGRectMake(0, 0, self.annotationView.frame.size.width, self.annotationView.frame.size.height)];
    }
    //[self.labelsView setFrame:CGRectMake(5+self.scrollView.contentOffset.x, self.scrollView.frame.size.height-self.labelsView.frame.size.height-5+self.scrollView.contentOffset.y, self.labelsView.frame.size.width, self.labelsView.frame.size.height)];
      

}
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale{
      /* [self.label setFrame:CGRectMake(self.label.frame.origin.x, self.label.frame.origin.y, labelSize.width*scale, labelSize.height*scale)];
    [self.label setFont:[UIFont systemFontOfSize:14*scale]];*/
    [self.annotationView setLINEWIDTH:scale];
   /* self.label.layer.contentsScale = [[UIScreen mainScreen] scale] *scale;
    [self.label setNeedsDisplay];*/
//    self.label.layer.contentsScale = [[UIScreen mainScreen] scale] * 5;
//    [self.label setNeedsDisplay];
//    self.annotationView.layer.contentsScale = [[UIScreen mainScreen] scale] * 4 *(scale -1) /10;
//
//    [self.annotationView setNeedsDisplay];
}
#pragma mark -
#pragma mark TableViewDelegate&Datasource Methods
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
    if (section == 0) {
        ret = self.annotationView.objects.count;
    }
    
    return ret;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString * ret = [[NSString alloc] init];
    if (section == 0)
        ret = [NSString stringWithFormat:@"%d objects",self.annotationView.objects.count];
    
    return  ret;
}


-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
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
     //
     if (cell == nil) {
     cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
     }
    
    //[cell setBackgroundColor:[UIColor colorWithRed:(230/255.0) green:(230/255.0) blue:(230/255.0) alpha:1.0]];
    [cell setBackgroundColor:[UIColor clearColor]];
    // Configure the cell...
    Box *b = [self.annotationView.objects   objectAtIndex:indexPath.row];
    if ([b.label length] != 0) {
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:b.label];
            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, b.label.length)];

            [attrString addAttribute:NSStrokeColorAttributeName value:b.color range:NSMakeRange(0, b.label.length)];
            [attrString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-1.75] range:NSMakeRange(0, b.label.length)];

            cell.textLabel.attributedText = attrString;

        }
        else{
            [cell.textLabel setText:b.label];
        }
            }
    else{
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@"(No Label)"];

            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0,10)];
            
            [attrString addAttribute:NSStrokeColorAttributeName value:b.color range:NSMakeRange(0, 10)];
            [attrString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-1.75] range:NSMakeRange(0, 10)];
            
            cell.textLabel.attributedText = attrString;
            
        }
        else{
                      [cell.textLabel setText:@"(No Label)"];
        }
    }
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d x %d",(int)((b.lowerRight.x - b.upperLeft.x)*self.imageView.image.size.width/self.annotationView.frame.size.width),(int)((b.lowerRight.y - b.upperLeft.y)*self.imageView.image.size.height/self.annotationView.frame.size.height)]];
    if (indexPath.row == [self.annotationView SelectedBox]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
   
    [self.annotationView setSelectedBox:indexPath.row];
    [self.annotationView setNeedsDisplay];
    [self.labelsView reloadData];
    [self listAction:self.labelsButton];
    Box *box = [self.annotationView.objects objectAtIndex:indexPath.row];
    [self.scrollView zoomToRect:CGRectMake(box.upperLeft.x+self.annotationView.frame.origin.x-10, box.upperLeft.y+self.annotationView.frame.origin.y-10, box.lowerRight.x - box.upperLeft.x+20, box.lowerRight.y - box.upperLeft.y+20) animated:YES];
    /**[self.label setFrame:CGRectMake(self.label.frame.origin.x, self.label.frame.origin.y, labelSize.width/self.scrollView.zoomScale, labelSize.height/self.scrollView.zoomScale)];
    [self.label setFont:[UIFont systemFontOfSize:14/self.scrollView.zoomScale]];*/
    [self.annotationView setLINEWIDTH:self.scrollView.zoomScale];
    [self selectedAnObject:YES];
    [self correctOrientation:box.upperLeft :box.lowerRight SuperviewFrame:self.annotationView.frame];

    
}
-(void)cancel{
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

-(void)sendingProgress:(float)prog{
    [self.sendingView.progressView setProgress:prog];
}
-(void)sendPhotoError{
    [self errorWithTitle:@"This image could not be sent" andDescription:@"Please, try again."];
    [self barButtonsEnabled:YES];
    [self.sendingView setHidden:YES];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator stopAnimating];
}
-(void)photoSentCorrectly:(NSString *)filename{
    if ([self.filename isEqualToString:filename]) {
        for (int i=0; i<[self.annotationView.objects count ]; i++) {
            [[self.annotationView.objects objectAtIndex:i ] setSent:YES] ;
        }
        [self saveDictionary];
    }
    else{
        NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
        for (int i=0; i<objects.count; i++) {
            [[objects objectAtIndex:i] setSent:YES];
        }
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    }
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:0];
    
    
    [self.navigationItem setHidesBackButton:NO];

        [self.sendingView setHidden:YES];
        [self.sendingView.progressView setProgress:0];
        [self.sendingView.activityIndicator stopAnimating];
    
    [self barButtonsEnabled:YES];
    [self.sendButton setEnabled:NO];
    [self.deleteButton setEnabled:NO];


    [dict removeObjectForKey:filename];
    [dict setObject:newdictnum forKey:filename];
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
}

-(void)photoNotOnServer:(NSString *)filename{
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username]];
    NSMutableArray *objects = [NSKeyedUnarchiver unarchiveObjectWithFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
    if (objects != nil) {
        for (int i=0; i<objects.count; i++) {
            [[objects objectAtIndex:i] setSent:NO];
        }
        [NSKeyedArchiver archiveRootObject:objects toFile:[[self.paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename ]];
        
    }
    NSNumber *newdictnum = [[NSNumber alloc]initWithInt:-objects.count-1];
    [dict removeObjectForKey:filename];
    [dict setObject:newdictnum forKey:filename];
    [dict writeToFile:[[self.paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",self.username] atomically:NO];
    [self sendAction:self.sendButton];
    
}


@end
