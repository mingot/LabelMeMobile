//
//  DetectirDescriptionViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorDescriptionViewController.h"
#import "Box.h"
#import "ConvolutionHelper.h"
#import "BoundingBox.h"

#import "UIImage+Resize.h"
#import "UIImage+HOG.h"
#import "UIImage+ImageAveraging.h"
#import "UIButton+CustomViews.h"
#import "SendingView+DetectorDescription.h"
#import "UIViewController+ShowAlert.h"

#import "UITableView+TextFieldAdditions.h"
#import "CustomUITableViewCell.h"


#define MAX_IMAGE_SIZE 300

//training results
#define SUCCESS 1
#define INTERRUPTED 2 //and not trained
#define FAIL 0


@interface DetectorDescriptionViewController()
{
    BOOL *_isFirstTraining;
}

@property (strong, nonatomic) SelectionHandler *selectionHandler;
@property (strong, nonatomic) UIBarButtonItem *editButton;
@property (strong, nonatomic) SendingView *sendingView;
@property (strong, nonatomic) UIImage *averageImage;
@property (strong, nonatomic) Detector *previousDetector; //to undo

@property (strong, nonatomic) UIBarButtonItem *executeButtonBar;
@property (strong, nonatomic) UIBarButtonItem *trainButtonBar;
@property (strong, nonatomic) UIBarButtonItem *infoButtonBar;
@property (strong, nonatomic) UIBarButtonItem *undoButtonBar;

//array with the properties to show in the description
@property (strong, nonatomic) NSMutableArray *detectorProperties;


- (IBAction)executeAction:(id)sender;
- (IBAction)trainAction:(id)sender;
- (IBAction)infoAction:(id)sender;
- (IBAction)undoAction:(id)sender;
- (IBAction)saveAction:(id)sender;

// wrapper to call the detector for training and testing
-(int) trainForImagesNames:(NSArray *)imagesNames;
-(void) testForImagesNames: (NSArray *) imagesNames;

//generate a unique id
- (NSString *)uuid;

//reload the detector images (average and hog) and show info, about the current detector in memory
- (void) loadDetectorInfo;


@end



@implementation DetectorDescriptionViewController



#pragma mark -
#pragma mark Setters and Getters


- (NSMutableArray *) detectorProperties
{
    if(!_detectorProperties && self.detector.weights != nil){
        
        //nsdate treatment
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy - HH:mm"];
        [formatter setTimeZone:[NSTimeZone localTimeZone]]; //time zone
        
        _detectorProperties = [[NSMutableArray alloc] init];
        [_detectorProperties addObject:[self dictionaryWithObject:self.detector.name forKey:@"Name"]];
        [_detectorProperties addObject:[self dictionaryWithObject:[self.detector.targetClasses componentsJoinedByString:@", "] forKey:@"Class"]];
        [_detectorProperties addObject:[self dictionaryWithObject:[formatter stringFromDate:self.detector.updateDate] forKey:@"Last Train"]];
        [_detectorProperties addObject:[self dictionaryWithObject:[NSString stringWithFormat:@"%d", self.detector.imagesUsedTraining.count] forKey:@"Images"]];
        
        //just shown on ipad
        [_detectorProperties addObject:[self dictionaryWithObject:[NSString stringWithFormat:@"%d", self.detector.numberSV.intValue] forKey:@"Number SV"]];
        [_detectorProperties addObject:[self dictionaryWithObject:[NSString stringWithFormat:@"%d", self.detector.numberOfPositives.intValue] forKey:@"Number Positives"]];
        [_detectorProperties addObject:[self dictionaryWithObject:[NSString stringWithFormat:@"HOG Dimensions: %@ x %@",[self.detector.sizes objectAtIndex:0],[self.detector.sizes objectAtIndex:1] ] forKey:@"HOG dimensions"]];
        [_detectorProperties addObject:[self dictionaryWithObject:[NSString stringWithFormat:@"%.2f seconds", self.detector.timeLearning.floatValue] forKey:@"Time Learning"]];
    }
    return _detectorProperties;
}


- (NSDictionary *) dictionaryWithObject:(id)value forKey:(NSString *)key
{
    // be cautious about each value introduced in the dictionary
    if(value==nil) value = @"";
    
    return [NSDictionary dictionaryWithObject:value forKey:key];
}


#pragma mark -
#pragma mark Life Cycle and Initialization

- (void)initializeBottomToolbar
{
    [self.bottomToolbar setBarStyle:UIBarStyleBlackOpaque];
    
    //buttons
    UIButton *executeButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [executeButtonView setImage:[UIImage imageNamed:@"executeIcon.png"] forState:UIControlStateNormal];
    [executeButtonView addTarget:self action:@selector(executeAction:) forControlEvents:UIControlEventTouchUpInside];
    self.executeButtonBar = [[UIBarButtonItem alloc] initWithCustomView:executeButtonView];
    UIButton *trainButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [trainButtonView setImage:[UIImage imageNamed:@"trainIcon.png"] forState:UIControlStateNormal];
    [trainButtonView addTarget:self action:@selector(trainAction:) forControlEvents:UIControlEventTouchUpInside];
    self.trainButtonBar = [[UIBarButtonItem alloc] initWithCustomView:trainButtonView];
    UIButton *infoButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [infoButtonView setImage:[UIImage imageNamed:@"infoIcon.png"] forState:UIControlStateNormal];
    [infoButtonView addTarget:self action:@selector(infoAction:) forControlEvents:UIControlEventTouchUpInside];
    self.infoButtonBar = [[UIBarButtonItem alloc] initWithCustomView:infoButtonView];
    UIButton *undoButtonView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomToolbar.frame.size.height,  self.bottomToolbar.frame.size.height)];
    [undoButtonView setImage:[UIImage imageNamed:@"restoreIcon.png"] forState:UIControlStateNormal];
    [undoButtonView addTarget:self action:@selector(undoAction:) forControlEvents:UIControlEventTouchUpInside];
    self.undoButtonBar = [[UIBarButtonItem alloc] initWithCustomView:undoButtonView];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.bottomToolbar setItems:[NSArray arrayWithObjects:flexibleSpace,self.executeButtonBar,flexibleSpace,self.trainButtonBar, flexibleSpace, self.infoButtonBar,flexibleSpace,self.undoButtonBar,flexibleSpace,nil]];
    
    self.undoButtonBar.enabled = NO;
}

- (void)initializeImageViews
{
    //image views
    self.detectorView.contentMode = UIViewContentModeScaleAspectFit;
    self.detectorView.clipsToBounds = YES;
    self.detectorView.layer.shadowColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1].CGColor;
    self.detectorView.layer.shadowOpacity = 1;
    self.detectorView.layer.shadowRadius = 5;
    self.detectorView.layer.shadowOffset = CGSizeMake(-1,-1);
    self.detectorHogView.contentMode = UIViewContentModeScaleAspectFit;
    self.detectorHogView.clipsToBounds = YES;
    self.detectorHogView.layer.shadowColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1].CGColor;
    self.detectorHogView.layer.shadowOpacity = 1;
    self.detectorHogView.layer.shadowRadius = 5;
    self.detectorHogView.layer.shadowOffset = CGSizeMake(-1,-1);
}

- (void)initializeAndAddSendingView
{
    //sending view, responsible for the waiting view
    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];//self.tabBarController.view.frame];
    [self.sendingView.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
    self.sendingView.delegate = self;
    self.sendingView.hidden = YES;
    [self.view addSubview:self.sendingView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.detector.name;
    
    self.detector.delegate = self;
    
    self.selectionHandler = [[SelectionHandler alloc] initWithViewController:self andDetecorResourceHandler:self.detectorResourceHandler];
    self.selectionHandler.delegate = self;
    
    self.scrollView.contentSize = self.containerView.frame.size;
    
    //controllers
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    self.executeController.delegate = self;
    
    
    //description table view
    self.descriptionTableView.layer.cornerRadius = 10;
    self.descriptionTableView.backgroundColor = [UIColor clearColor];
    
    [self initializeImageViews];
    [self initializeBottomToolbar];
    [self initializeAndAddSendingView];
    
    //Check if the detector exists.
    if(self.detector == nil){
        NSLog(@"New detector");
        self.detector = [[Detector alloc] init];
        self.detector.delegate = self;
        _isFirstTraining = YES;
        [self.selectionHandler addNewDetector];
        
    }else NSLog(@"Loading detector: %@", self.detector.name);
    
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadDetectorInfo];
    
    // Register keyboard events
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Unregister keyboard events
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Actions

- (IBAction)executeAction:(id)sender
{
    self.executeController.detectors = [NSArray arrayWithObject:self.detector];
    self.executeController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.executeController animated:NO];
}

- (IBAction)trainAction:(id)sender
{    
    [self.selectionHandler selectTrainingImages];
    
    //let's wait for the SelectionHandlerDelegate answer to begin the training
}



- (IBAction)infoAction:(id)sender
{
    self.navigationController.navigationBarHidden = YES;
    [self.sendingView initializeForInfoOfDetector:self.detector];
}

- (IBAction)undoAction:(id)sender
{    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Are you sure you want to undo the training?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [alert show];
}



- (IBAction)saveAction:(id)sender
{
    self.detector.updateDate = [NSDate date];
    [self.detectorResourceHandler saveDetector:self.detector withImage:self.averageImage];
    self.detectorView.image = self.averageImage;
    
    [self loadDetectorInfo];
    [self.delegate updateDetector:self.detector];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Ok"]) {
        self.detector = self.previousDetector;
        self.undoButtonBar.enabled = NO;
        [self saveAction:self];
    }
}


#pragma mark -
#pragma mark SelectionHandlerDelegate


- (void) trainDetectorForClasses:(NSArray *)classes
          andTrainingImagesNames:(NSArray *)trainingImagesNames
              andTestImagesNames:(NSArray *)testImagesNames
{
    
    //first time training specify name of the detector
    if(self.detector.targetClasses == nil){
        self.detector.targetClasses = classes;
        NSString *className = [self.detector.targetClasses componentsJoinedByString:@"+"];
        self.detector.name = [NSString stringWithFormat:@"%@-Detector",className];
        self.detector.detectorID = [NSString stringWithFormat:@"%@%@",className,[self uuid]];
    }
    
    //save the current detector for undo purposes
    self.previousDetector = [[Detector alloc] init];
    self.previousDetector = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.detector]]; //trick to copy the object
    
    [self.sendingView initializeForTraining];
    self.navigationController.navigationBarHidden = YES;

    
    //train in a different queue
    dispatch_queue_t myQueue = dispatch_queue_create("learning_queue", 0);
    dispatch_async(myQueue, ^{
        __block int trainingState = [self trainForImagesNames:trainingImagesNames];
        if (trainingState == SUCCESS) {
            [self.sendingView showMessage:@"Finished training"];
            [self testForImagesNames:testImagesNames];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if(trainingState == SUCCESS){
                [self updateProgress:1];
                
                //update view of the detector
                if(self.previousDetector != nil) self.undoButtonBar.enabled = YES;
                [self saveAction:self];
                [self loadDetectorInfo];
                
            }else if(trainingState == FAIL){
                [self.sendingView showMessage:@"Error training"];
            
                [self showAlertWithTitle:@"Error Training" andDescription:@"Shape on training set not allowed.\n Make sure all the labels have a similar shape and that are not too big."];
                
                if(_isFirstTraining){
                    self.navigationController.navigationBarHidden = NO;
                    [self.navigationController popViewControllerAnimated:YES];
                }
                
            }else if(trainingState == INTERRUPTED){
                //if detector not even trained with one iteration(cancelled before) then rescue previous classifer (undo)
                self.detector = self.previousDetector;
                self.undoButtonBar.enabled = NO;
                
                if(_isFirstTraining){
                    self.navigationController.navigationBarHidden = NO;
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            
            [self.sendingView stopAfterTraining];            
        });
    });

}

- (Detector *) currentDetector
{
    return self.detector;
}


#pragma mark -
#pragma mark SendingViewDelegate

- (void) cancel
{
    if([self.sendingView.sendingViewID isEqualToString:@"info"]){
        self.sendingView.hidden = YES;
        self.navigationController.navigationBarHidden = NO;
    }else if([self.sendingView.sendingViewID isEqualToString:@"train"]){
        [self.detector cancelTraining];
        self.sendingView.cancelButton.enabled = NO;
        self.sendingView.sendingViewID = @"info";
    }
}

#pragma mark -
#pragma mark DetectorDelegate


-(void) sendMessage:(NSString *)message
{
    [self.sendingView showMessage:message];
}

-(void) updateProgress:(float)prog
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sendingView.progressView setProgress:prog animated:YES];
    });
}


#pragma mark -
#pragma mark ExecuteDetectorViewCotrollerDelegate

- (void) updateDetector:(Detector *)detector
{
    //received when updating detector threshold from execute controller
    [self.delegate updateDetector:detector];
}

#pragma mark -
#pragma mark Table View Delegate and Datasource

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    int orientation = [[UIDevice currentDevice] orientation];
    BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad;
    
//    if([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad) return self.detectorProperties.count;
//    else return 4;
    
    if(isIpad && orientation == UIInterfaceOrientationPortrait) return self.detectorProperties.count;
    else if(isIpad) return 6;
    else if(!isIpad && orientation == UIInterfaceOrientationPortrait) return 4;
    else return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *property = [self.detectorProperties objectAtIndex:indexPath.row];
    NSString *propertyName = [[property allKeys] objectAtIndex:0];

    static NSString *kCellIdent = @"DetectorDescriptionTableCell";
    CustomUITableViewCell *cell = [[CustomUITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellIdent];
    if (!cell)cell = [[CustomUITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2  reuseIdentifier:kCellIdent];
    
    if([propertyName isEqualToString:@"Name"]){
        cell.isEditable = YES;
        cell.textField.placeholder = [property objectForKey:propertyName];
        cell.textField.delegate = self;
        cell.textField.returnKeyType = UIReturnKeyDone;
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        if (!_isFirstTraining) cell.textField.text = [property objectForKey:propertyName];
    }else{
        cell.detailTextLabel.text = [property objectForKey:propertyName];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = propertyName;
    cell.textLabel.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor colorWithWhite:247/256.0 alpha:1];
    
    return cell;
    
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if([cell.textLabel.text isEqualToString:@"Name"]){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.descriptionTableView makeFirstResponderForIndexPath:indexPath];
    }else if([cell.textLabel.text isEqualToString:@"Description"]){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.descriptionTableView makeFirstResponderForIndexPath:indexPath];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSString *text = [[textField text] stringByReplacingCharactersInRange:range withString:string];
	NSIndexPath *indexPath = [self.descriptionTableView indexPathForFirstResponder];
	UITableViewCell *cell = [self.descriptionTableView cellForRowAtIndexPath:indexPath];
    
	if([cell.textLabel.text isEqualToString:@"Name"]) self.detector.name = text;
    
	return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self.delegate updateDetector:self.detector];
    [textField resignFirstResponder];
    self.detectorProperties = nil;
    self.title = self.detector.name;
    [self.descriptionTableView reloadData];
	return YES;
}


#pragma mark -
#pragma mark Memory Management

-(void) didReceiveMemoryWarning
{
    NSLog(@"Memory warning received!!!");
    [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark Keyboard Events

-(void)keyboardDidShow:(NSNotification *)notif
{
    self.scrollView.scrollEnabled = YES;
    
	// Get the origin of the keyboard when it finishes animating
	NSDictionary *info = [notif userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	// Get the top of the keyboard in view's coordinate system.
	// We need to set the bottom of the scrollview to line up with it
	CGRect keyboardRect = [aValue CGRectValue];
	CGFloat keyboardTop = keyboardRect.origin.y;
    
	// Resize the scroll view to make room for the keyboard
    CGRect viewFrame = self.scrollView.frame;
	viewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
	
	self.scrollView.frame = viewFrame;
    [self.scrollView scrollRectToVisible:self.descriptionTableView.frame animated:YES];
}


-(void)keyboardDidHide:(NSNotification *)notif
{
    self.scrollView.scrollEnabled = NO;
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.view.frame.size.height);
}

#pragma mark -
#pragma mark Private methods


-(int) trainForImagesNames:(NSArray *)imagesNames
{
    //initialization
    self.detector.imagesUsedTraining = [[NSMutableArray alloc] init];
    
    //constructs the training set of the images
    TrainingSet *trainingSet = [[TrainingSet alloc] initForTargetClasses:self.detector.targetClasses
                                                          forImagesNames:imagesNames
                                                         withFileHandler:_detectorResourceHandler];
    
    //save it associated to a detector
    self.detector.imagesUsedTraining = [NSMutableArray arrayWithArray:trainingSet.imagesNames];
    
    //3 additional images (3 abstract art) added apart.
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images in the training set: %d + 3",trainingSet.images.count-3]];
        
    //obtain the image average of the groundtruth images 
    NSArray *listOfImages = [trainingSet getImagesOfBoundingBoxes];
    self.averageImage = [UIImage imageAverageFromImages:listOfImages];
    self.detectorView.image = self.averageImage;
    
    //train
    [self updateProgress:0.05];
    [self.sendingView showMessage:@"Training begins!"];
    int successTraining = [self.detector trainOnSet:trainingSet
                                          forMaxHOG:[self.detectorResourceHandler getHogFromPreferences]];
    [self.sendingView showMessage:@"Finished training"];
    
    return successTraining;
}


- (void) testForImagesNames: (NSArray *)imagesNames
{
    //initialization
    TrainingSet *testSet = [[TrainingSet alloc] initForTargetClasses:self.detector.targetClasses
                                                      forImagesNames:imagesNames
                                                     withFileHandler:_detectorResourceHandler];
    
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images in the test set: %d",testSet.images.count]];
    [self.sendingView showMessage:@"Testing begins!"];
    [self.detector testOnSet:testSet atThresHold:0.0];
    [self.sendingView showMessage:@"Finished testing"];
}


- (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *result = (__bridge NSString *) uuidStringRef;
    return [result substringToIndex:8];
}

- (void) loadDetectorInfo
{
    //images
//    self.detectorHogView.image = [UIImage hogImageFromFeatures:self.detector.weightsP withSize:self.detector.sizesP];
    self.detectorView.image = [UIImage imageWithContentsOfFile:self.detector.averageImagePath];
    
    self.detectorProperties = nil;
    [self.descriptionTableView reloadData];
    [self.view setNeedsDisplay];
}

- (void)viewDidUnload {
    [self setDescriptionTableView:nil];
    [self setScrollView:nil];
    [self setContainerView:nil];
    [self setContainerView:nil];
    [super viewDidUnload];
}
@end
