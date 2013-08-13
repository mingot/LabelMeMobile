//
//  AnnotationToolViewController.m
//  AnnotationTool
//
//  Created by Dolores Blanco Almazán on 31/03/12.
//  Updated by Josep Marc Mingot.
//  Copyright 2012 CSAIL. All rights reserved.
//

#import "TagViewController.h"
#import "LabelsResourcesHandler.h"
#import "LMUINavigationController.h"
#import "UIButton+CustomViews.h"
#import "UIViewController+ShowAlert.h"



@interface TagViewController()
{
    ServerConnection *_serverConnection;
    
    BOOL *_isBoxSelected;
    BOOL *_isZoomIn;
    
    NSMutableSet *_recentLabels; //buffer with the recent labels for keyboard word suggestion
}

@property (strong, nonatomic) LabelsResourcesHandler *labelsResourceHandler;
@property (strong, nonatomic) UITableView *labelsView;
@property (strong, nonatomic) UIButton *tip;
@property (strong, nonatomic) UIButton *labelsButton;
@property (strong, nonatomic) SendingView *sendingView;


// Save thumbnail and boxes
// Notify the delegate to reload
- (void) saveStateOnDisk;

// Just enable the scroll of pages in the infinite loop if: (1) no box selected and (2) not zoom in
- (void) updateScrollPersmission;

@end


@implementation TagViewController

#pragma mark -
#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.labelsView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _serverConnection = [[ServerConnection alloc] init];
        _serverConnection.delegate = self;
        
        _recentLabels = [[NSMutableSet alloc] init];
        
    }
    return self;
}

- (void) initializeBottomToolbar
{
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
}

- (void) initializeAndAddTipView
{
    //tip
    CGRect tipRect = CGRectMake(25, 2*self.view.frame.size.height/3, self.view.frame.size.width/2, self.view.frame.size.height/3);
    self.tip = [[UIButton alloc] initWithFrame:tipRect];
    [self.tip setBackgroundImage:[[UIImage imageNamed:@"globo.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )] forState:UIControlStateNormal];
    UILabel *tiplabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, self.tip.frame.size.width-24, self.tip.frame.size.height-24)];
    tiplabel.numberOfLines = 4;
    tiplabel.text = @"Tip:\nPress this button \nto add a bounding box!";
    tiplabel.textColor = [UIColor redColor];
    tiplabel.backgroundColor = [UIColor clearColor];
    [self.tip addSubview:tiplabel];
    [self.tip addTarget:self action:@selector(hideTip:) forControlEvents:UIControlEventTouchUpInside];
    
    //Show only the first time the program loads
    self.tip.hidden = YES;
    if (![@"1" isEqualToString:[[NSUserDefaults standardUserDefaults]
                                objectForKey:@"Avalue"]]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"Avalue"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.tip.hidden = NO;
    }
    
    [self.view addSubview:self.tip];
}

- (void) initializeAndAddSendingView
{

    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    self.sendingView.hidden = YES;
    self.sendingView.textView.text = @"Uploading to the server...";
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.sendingView.delegate = self;
    [self.view addSubview:self.sendingView];
}

#pragma mark -
#pragma mark View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //load the resources direction for the current filename
    self.labelsResourceHandler = [[LabelsResourcesHandler alloc] initForUsername:self.username andFilename:self.filename];
    
    //solid color for the navigation bar
    [self.navigationController.navigationBar setBackgroundImage:[LMUINavigationController drawImageWithSolidColor:[UIColor redColor]] forBarMetrics:UIBarMetricsDefault];
    
    //load and setup other window views
    [self initializeBottomToolbar];
    [self initializeAndAddTipView];
    [self initializeAndAddSendingView];
    
    
//    //labelsview (for the table showing the boxes in the image)
//    [self.labelsView setBackgroundColor:[UIColor clearColor]];
//    [self.labelsView setHidden:YES];
//    [self.labelsView setDelegate:self];
//    [self.labelsView setDataSource:self];
//    [self.labelsView setRowHeight:30];
//    self.labelsView.scrollEnabled = NO;
//    UIImage *globo = [[UIImage imageNamed:@"globo4.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )];
//    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.scrollView.frame];
//    [backgroundView setImage:globo];
//    [self.labelsView setBackgroundView:backgroundView];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    //register for notifications if box is selected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isBoxSelected:) name:@"isBoxSelected" object:nil];

    //scroll initialization
    int index = [self.items indexOfObject:self.filename];
    [self.infiniteLoopView initializeAtIndex:index];
    
////        [self selectedAnObject:NO];
////        if (self.tagView.boxes.count > 0)
////            [self.labelsView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];

}


- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    //save thumbnail and dictionary
    [self saveStateOnDisk];
    [_recentLabels removeAllObjects];
    
//    if (!self.tagView.userInteractionEnabled){
//        self.tagView.userInteractionEnabled = YES;
//        self.scrollView.frame = CGRectMake(0 , 0, self.view.frame.size.width, self.view.frame.size.height-self.bottomToolbar.frame.size.height);
////        [self.label resignFirstResponder];
//    }
    
//    self.labelsView.hidden = YES;
//    self.labelsButton.selected = NO;
//    if (![self.sendingView isHidden]) self.sendingView.hidden = YES;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark IBAction 

-(IBAction)addAction:(id)sender
{
 
    if (![self.tip isHidden])[self.tip setHidden:YES];
    
    [self.tagImageView.tagView addBoxInVisibleRect:[self.tagImageView getVisibleRect]];

    if (!self.labelsView.hidden) {
        [self.labelsView setHidden:YES];
        [self.labelsButton setSelected:NO];
    }

    //Update the number of boxes to be send
    self.labelsResourceHandler.boxesNotSent++;
}


-(IBAction)sendAction:(id)sender
{
    //save state
    [self saveStateOnDisk];
    [self barButtonsEnabled:NO];
    
    //sending view
    self.sendingView.hidden = NO;
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator startAnimating];
    [self.tagImageView resetZoomView];
    [self sendPhoto];
}


-(IBAction)deleteAction:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]  initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Object" otherButtonTitles:nil, nil];
    actionSheet.actionSheetStyle = UIBarStyleBlackTranslucent;
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
}

-(IBAction)listAction:(id)sender
{
    NSLog(@"Boxes to be send: %d", self.labelsResourceHandler.boxesNotSent);
    if (!_labelsResourceHandler.isImageSent) {
        NSLog(@"Image not sent");
    }else NSLog(@"Image sent");
    
//    [self.labelsView reloadData];
//    if (self.labelsView.hidden) {
//        
//        //make buttons disappear
//        self.previousButton.hidden = YES;
//        self.nextButton.hidden = YES;
//    
//        if (self.tagView.boxes.count == 0) {
//            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x,
//                                                 self.scrollView.frame.size.height-0.19375*self.view.frame.size.width+self.scrollView.contentOffset.y,
//                                                 self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,
//                                                 0.19375*self.view.frame.size.width)];
//            
//        }else if (self.tagView.boxes.count*self.labelsView.rowHeight >= self.scrollView.frame.size.height/3) {
//            [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width+self.scrollView.contentOffset.x,
//                                                 2*self.scrollView.frame.size.height/3-0.078125*self.view.frame.size.width+self.scrollView.contentOffset.y,
//                                                 self.scrollView.frame.size.width-0.03125*self.view.frame.size.width,
//                                                 self.scrollView.frame.size.height/3+0.0625*self.view.frame.size.width)];
//            
//        }else [self.labelsView setFrame:CGRectMake(0.015625*self.view.frame.size.width + self.scrollView.contentOffset.x,
//                                                 self.scrollView.frame.size.height - self.tagView.boxes.count*self.labelsView.rowHeight-0.078125*self.view.frame.size.width + self.scrollView.contentOffset.y,
//                                                 self.scrollView.frame.size.width - 0.03125*self.view.frame.size.width,
//                                                 self.tagView.boxes.count*self.labelsView.rowHeight+0.0625*self.view.frame.size.width+5)];
//        self.labelsView.layer.masksToBounds = YES;
//        [self.labelsView.layer setCornerRadius:10];
//        
//    }else{
//        self.previousButton.hidden = NO;
//        self.nextButton.hidden = NO;
//    }
//    
//    [self.labelsButton setSelected:!self.labelsButton.selected];
//    [self.labelsView setHidden:!self.labelsView.hidden];
    
}

-(IBAction)hideTip:(id)sender
{
    [self.tip setHidden:YES];
}


#pragma mark -
#pragma mark ActionSheetDelegate Methods

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        int num = self.tagImageView.tagView.boxes.count;

        if( num<1 || self.tagImageView.tagView.selectedBox == -1)
            return;

        BOOL boxWasSent = [[self.tagImageView.tagView.boxes objectAtIndex:self.tagImageView.tagView.selectedBox] sent];
        if(!boxWasSent) self.labelsResourceHandler.boxesNotSent--;
        
        [self.tagImageView.tagView removeSelectedBox];
        
        [self saveStateOnDisk];
    }
}


#pragma mark -
#pragma mark TagViewDelegate Methods

-(void)objectModified
{
    // if the box was sent, update 
    Box *selectedBox = [self.tagImageView.tagView getSelectedBox];
    [_recentLabels addObject:selectedBox.label];
    if(selectedBox && selectedBox.sent){
        selectedBox.sent = NO;
        self.labelsResourceHandler.boxesNotSent ++;
    }
    
    [self saveStateOnDisk];
}


#pragma mark -
#pragma mark NSNotificationCenter Messages

-(void)isBoxSelected:(NSNotification *) notification
{
    
    NSNumber *isSelected = [notification object];

    _isBoxSelected = isSelected.boolValue;
    [self updateScrollPersmission];
    
    self.deleteButton.enabled = isSelected.boolValue;
    Box *selectedBox = [self.tagImageView.tagView getSelectedBox];
    if(!selectedBox.sent) self.sendButton.enabled = YES;
    self.sendButton.enabled = self.labelsResourceHandler.boxesNotSent!=0 ?  YES : NO;
//    [self.labelsView reloadData];
}


#pragma mark -
#pragma mark TableViewDelegate&Datasource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;//self.tagImageView.tagView.boxes.count;
    else return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) return @"0";//[NSString stringWithFormat:@"%d objects",self.tagImageView.tagView.boxes.count];
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

//    [cell setBackgroundColor:[UIColor clearColor]];
//    Box *b = nil;//[self.tagImageView.tagView.boxes objectAtIndex:indexPath.row];
//    if (b.label.length != 0) {
//        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
//            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:b.label];
//            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, b.label.length)];
//            [attrString addAttribute:NSStrokeColorAttributeName value:b.color range:NSMakeRange(0, b.label.length)];
//            [attrString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-1.75] range:NSMakeRange(0, b.label.length)];
//
//            cell.textLabel.attributedText = attrString;
//            
//        }else [cell.textLabel setText:b.label];
//        
//    }else{
//        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)]) {
//            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:@"(No Label)"];
//
//            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0,10)];
//            [attrString addAttribute:NSStrokeColorAttributeName value:b.color range:NSMakeRange(0, 10)];
//            [attrString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:-1.75] range:NSMakeRange(0, 10)];
//            
//            cell.textLabel.attributedText = attrString;
//            
//        }else [cell.textLabel setText:@"(No Label)"];
//        
//    }
////    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d x %d",(int)((b.lowerRight.x - b.upperLeft.x)*self.imageView.image.size.width/self.tagImageView.tagView.frame.size.width),(int)((b.lowerRight.y - b.upperLeft.y)*self.imageView.image.size.height/self.tagImageView.tagView.frame.size.height)]];
//    
//    [cell.detailTextLabel setText:@"TBD"];
//    
//    if (indexPath.row == self.tagImageView.tagView.selectedBox)
//        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
//    
//    else [cell setAccessoryType:UITableViewCellAccessoryNone];
//    
//    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    [self.tagView setSelectedBox:indexPath.row];
//    [self.tagView setNeedsDisplay];
//    [self.labelsView reloadData];
//    [self listAction:self.labelsButton];
//    Box *box = [self.tagView.boxes objectAtIndex:indexPath.row];
//    [self.scrollView zoomToRect:CGRectMake(box.upperLeft.x+self.tagView.frame.origin.x-10, box.upperLeft.y+self.tagView.frame.origin.y-10, box.lowerRight.x - box.upperLeft.x+20, box.lowerRight.y - box.upperLeft.y+20) animated:YES];
//    [self.tagView setLineWidthForZoomFactor:self.scrollView.zoomScale];
//    [self selectedAnObject:YES];
}


#pragma mark -
#pragma mark Sending View Delegate


-(void)cancel
{
    [_serverConnection cancelRequestFor:0];
    [self.navigationItem setHidesBackButton:NO];
    [self.sendingView setHidden:YES];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator stopAnimating];
    [self barButtonsEnabled:YES];
    [self.deleteButton setEnabled:NO];
}

#pragma mark -
#pragma mark InfiniteLoopDelegate & InfiniteLoopDataSource

- (UIView *) viewForIndex:(int)index
{
    
    //set the resource handler with the correct filename
    NSString *requestedFilename = [self.items objectAtIndex:index];
    self.labelsResourceHandler.filename = requestedFilename;
    
    //construct the view
    TagImageView *requestedView = [[TagImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    requestedView.image = [self.labelsResourceHandler getImage];
    requestedView.tagView.boxes = [self.labelsResourceHandler getBoxes];
    
    //restore the |self.labelsResourceHandler|
    self.labelsResourceHandler.filename = self.filename;
    
    return requestedView;
}

- (int) numberOfViews
{
    return self.items.count;
}

- (void) didShowView:(UIView *)view forIndex:(int)currentIndex;
{    
    //title
    self.title = [NSString stringWithFormat:@"%d of %d", currentIndex + 1, self.items.count];
    
    self.filename = [self.items objectAtIndex:currentIndex];
    self.labelsResourceHandler.filename = self.filename;
    
    //hook current view with the delegate
    self.tagImageView = (TagImageView *)view;
    self.tagImageView.delegate = self;
    self.tagImageView.tagView.delegate = self;
    [self.tagImageView reloadForRotation];
    [self.tagImageView.tagView setDataSourceForKeyboardSuggestions:self]; //for label suggestion on the keyboard
    
    
    //check if boxes not saved on the server
    [self.sendButton setEnabled:YES];
    if (self.labelsResourceHandler.boxesNotSent == 0) [self.sendButton setEnabled:NO];
    
    [self.view setNeedsDisplay];
}

#pragma mark -
#pragma mark KeyboardHandlerDataSource

- (NSArray *) arrayOfWords
{
    //returns the list of the recent labels buffered in this session
    return _recentLabels.allObjects;
}


#pragma mark -
#pragma mark TagImageViewDelegate

- (void) scrollDidEndZoomingAtScale:(float) scale
{
    _isZoomIn = scale!=1 ? YES:NO;
    [self updateScrollPersmission];
}

#pragma mark -
#pragma mark Rotation

- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
    //deselect boxes (avoid problems with self.label)
    self.tagImageView.tagView.selectedBox = -1;
    
    [self.tagImageView reloadForRotation];
    
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
    [self showAlertWithTitle:@"This image could not be sent" andDescription:@"Please, try again."];
    [self barButtonsEnabled:YES];
    [self.sendingView setHidden:YES];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator stopAnimating];
}

-(void)photoSentCorrectly:(NSString *)filename
{

    // Modify the flag of the boxes
    for (int i=0; i<self.tagImageView.tagView.boxes.count; i++)
        [[self.tagImageView.tagView.boxes objectAtIndex:i] setSent:YES];

    [self.navigationItem setHidesBackButton:NO];

    [self.sendingView setHidden:YES];
    [self.sendingView.progressView setProgress:0];
    [self.sendingView.activityIndicator stopAnimating];
    
    [self barButtonsEnabled:YES];
    [self.sendButton setEnabled:NO];
    [self.deleteButton setEnabled:NO];
    
    self.labelsResourceHandler.isImageSent = YES;
}

-(void)photoNotOnServer:(NSString *)filename
{
    NSArray *boxes = [self.labelsResourceHandler getBoxes];
    if (boxes != nil) {
        for (int i=0; i<boxes.count; i++)
            [[boxes objectAtIndex:i] setSent:NO];
    }
    
    self.labelsResourceHandler.boxesNotSent = boxes.count;
    
    [self sendAction:self.sendButton];
}

#pragma mark -
#pragma mark Private methods

- (void) saveStateOnDisk
{
    [self.labelsResourceHandler saveThumbnail:[self.tagImageView takeThumbnailImage]];
    [self.labelsResourceHandler saveBoxes:self.tagImageView.tagView.boxes];
    
    [self.delegate reloadTable];
}


-(void)sendPhoto
{
    CGPoint point = CGPointMake(self.tagImageView.image.size.width/self.tagImageView.tagView.frame.size.width, self.tagImageView.image.size.height/self.tagImageView.tagView.frame.size.height);
    
    NSMutableArray *boxes = [NSMutableArray arrayWithArray:self.tagImageView.tagView.boxes];
    NSString *boxesPath = [self.labelsResourceHandler getBoxesPath];
    if (!self.labelsResourceHandler.isImageSent)
        [_serverConnection sendPhoto:self.tagImageView.image filename:self.filename path:boxesPath withSize:point andAnnotation:boxes];
    else [_serverConnection updateAnnotationFrom:self.filename withSize:point :boxes];
}

- (void) updateScrollPersmission
{
    if(!_isBoxSelected && !_isZoomIn) [self.infiniteLoopView disableScrolling:NO];
    else [self.infiniteLoopView disableScrolling:YES];
}

-(void)barButtonsEnabled:(BOOL)value
{
    [self.addButton setEnabled:value];
    [self.sendButton setEnabled:value];
    [self.labelsButton setEnabled:value];
    [self.deleteButton setEnabled:value];
    [self.navigationItem setHidesBackButton:!value];
}


@end
