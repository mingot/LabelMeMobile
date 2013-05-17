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

#import "UIImage+Resize.h"
#import "UIImage+HOG.h"
#import "UIButton+CustomViews.h"

#import "EditableTableViewCell.h"
#import "UITableView+TextFieldAdditions.h"


#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define DETECTORS 3
#define USER 4
#define MAX_IMAGE_SIZE 300

//self.firstTrainingState
#define NOT_FIRST 0
#define INITIATED 1
#define INTERRUPTED 2


@interface DetectorDescriptionViewController()

@property BOOL trainingWentGood;
@property (strong, nonatomic) UIImage *averageImage;
@property int firstTraingState; //0: not first training, 1: first training initiated, 2: first training interrupted


// wrapper to call the detector for training and testing
-(void) trainForImagesNames:(NSArray *)imagesNames;
-(void) testForImagesNames: (NSArray *) imagesNames;

//generate a unique id
- (NSString *)uuid;

// average per pixel image
-(UIImage *) imageAveraging:(NSArray *) images;

//reload the detector images (average and hog) and show info, about the current detector in memory
- (void) loadDetectorInfo;


@end



@implementation DetectorDescriptionViewController



#pragma mark -
#pragma mark Setters and Getters

-(NSArray *) availablePositiveImagesNames
{
    //get the images for the selected class (self.svmClassifier.targetClass)
    if(!_availablePositiveImagesNames){
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.resourcesPaths objectAtIndex:THUMB]] error:NULL];
        
        for(NSString *imageName in imagesList){
            NSString *path = [[self.resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
            NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
            for(Box *box in objects)
                if([box.label isEqualToString:self.svmClassifier.targetClass] && [list indexOfObject:imageName]==NSNotFound)
                        [list addObject:imageName];
        }
        _availablePositiveImagesNames = [NSArray arrayWithArray:list];
    }
    
    return _availablePositiveImagesNames;
}


- (NSMutableArray *) classifierProperties
{
    if(!_classifierProperties && self.svmClassifier.weights != nil){
        
        //nsdate treatment
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"mm/dd/yyyy - hh:mm"];
        [formatter setTimeZone:[NSTimeZone localTimeZone]]; //time zone
        
        
        _classifierProperties = [[NSMutableArray alloc] init];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:self.svmClassifier.name forKey:@"Name"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:self.svmClassifier.targetClass forKey:@"Class"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[formatter stringFromDate:self.svmClassifier.updateDate] forKey:@"Last Train"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", self.svmClassifier.imagesUsedTraining.count] forKey:@"Images"]];
    }
    return _classifierProperties;
}



#pragma mark -
#pragma mark Life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.firstTraingState = NOT_FIRST;
    self.title = self.svmClassifier.name;
    self.svmClassifier.delegate = self;
    self.resourcesPaths = [NSArray arrayWithObjects:
                           [self.userPath stringByAppendingPathComponent:@"images"],
                           [self.userPath stringByAppendingPathComponent:@"thumbnail"],
                           [self.userPath stringByAppendingPathComponent:@"annotations"],
                           [self.userPath stringByAppendingPathComponent:@"Detectors"],
                           self.userPath, nil];
    self.scrollView.contentSize = self.showView.frame.size;
    
    //controllers
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    
    //set labels
    self.detectorView.contentMode = UIViewContentModeScaleAspectFill;
    self.detectorHogView.contentMode = UIViewContentModeScaleAspectFill;
    
    //bottom toolbar
    [self.bottomToolbar setBarStyle:UIBarStyleBlackOpaque];
    
    //top toolbar icons
    //self.editButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton buttonBarWithTitle:@"Edit" target:self action:@selector(editAction:)]];
    //self.navigationItem.rightBarButtonItem = self.editButton;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton buttonBarWithTitle:@"Back" target:self.navigationController action:@selector(popViewControllerAnimated:)]];
    self.navigationItem.leftBarButtonItem = backButton;
    
    //description table view
    self.descriptionTableView.layer.cornerRadius = 10;
    self.descriptionTableView.backgroundColor = [UIColor clearColor];//
    
    //bottombar
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
    [self.bottomToolbar setItems:[NSArray arrayWithObjects:self.executeButtonBar,flexibleSpace,self.trainButtonBar, flexibleSpace, self.infoButtonBar,flexibleSpace,self.undoButtonBar,nil]];
    
    self.undoButtonBar.enabled = NO;

    //Check if the classifier exists.
    if(self.svmClassifier.weights == nil){
        NSLog(@"New classifier");
        //show modal to select the target class
        self.modalTVC = [[ModalTVC alloc] init];
        self.modalTVC.showCancelButton = YES;
        self.modalTVC.delegate = self;
        self.modalTVC.modalTitle = @"Select Class";
        self.modalTVC.multipleChoice = NO;
        self.modalTVC.data = self.availableObjectClasses;
        self.modalTVC.doneButtonTitle = @"Create";
        [self presentModalViewController:self.modalTVC animated:YES];
        self.firstTraingState = INITIATED;
        
    }else{
        NSLog(@"Loading old classifier");
        //storing the previous classifier using the nscoding for object copy
        self.previousSvmClassifier = [[Classifier alloc] init];
        self.previousSvmClassifier = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.svmClassifier]];
    }
    
    
    //sending view, responsible for the waiting view
    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    [self.sendingView.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
    self.sendingView.delegate = self;
    self.sendingView.hidden = YES;
    [self.view addSubview:self.sendingView];
    
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadDetectorInfo];
    
    // Register keyboard events
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    if(self.firstTraingState == INTERRUPTED) [self.navigationController popViewControllerAnimated:YES];
    else if(self.firstTraingState == INITIATED){
        [self trainAction:self];
    }
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
    self.executeController.svmClassifier = self.svmClassifier;
    self.executeController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.executeController animated:YES];
}

- (IBAction)trainAction:(id)sender
{
    
    //show modal to select training positives for the selected class
    self.modalTVC = [[ModalTVC alloc] init];
    self.modalTVC.delegate = self;
    self.modalTVC.modalTitle = @"Select Training Images";
    self.modalTVC.doneButtonTitle = @"Train";
    self.modalTVC.multipleChoice = NO;
    self.availablePositiveImagesNames = nil; //to reset
    NSMutableArray *imagesList = [[NSMutableArray alloc] init];
    for(NSString *imageName in self.availablePositiveImagesNames){
        [imagesList addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.resourcesPaths objectAtIndex:THUMB],imageName]]];
        if(self.svmClassifier.imagesUsedTraining == nil || [self.svmClassifier.imagesUsedTraining indexOfObject:imageName]!= NSNotFound)
            [self.modalTVC.selectedItems addObject:[NSNumber numberWithInt:(imagesList.count-1)]];
    }
    self.modalTVC.showCancelButton = YES;
    self.modalTVC.data = imagesList;
    [self.modalTVC.view setNeedsDisplay];
    [self presentModalViewController:self.modalTVC animated:YES];

    
    //let's wait for the modalTVCDelegate answer to begin the training
}




- (IBAction)infoAction:(id)sender
{
    self.navigationController.navigationBarHidden = YES;
    self.sendingView.hidden = NO;
    self.sendingView.cancelButton.hidden = NO;
    self.sendingView.progressView.hidden = YES;
    [self.sendingView.messagesStack removeAllObjects];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Detector %@", self.svmClassifier.name]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images:%d", self.svmClassifier.imagesUsedTraining.count]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of Support Vectors:%@", self.svmClassifier.numberSV]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of positives %@", self.svmClassifier.numberOfPositives]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"HOG Dimensions:%@ x %@",[self.svmClassifier.sizes objectAtIndex:0],[self.svmClassifier.sizes objectAtIndex:1] ]];
    [self.sendingView showMessage:@"**** Results on the training set ****"];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Precision:%.1f",[(NSNumber *)[self.svmClassifier.precisionRecall objectAtIndex:0] floatValue]]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Recall:%.1f", [(NSNumber *)[self.svmClassifier.precisionRecall objectAtIndex:1] floatValue]]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Time learning:%.1f", self.svmClassifier.timeLearning.floatValue]];
}

- (IBAction)undoAction:(id)sender
{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Are you sure you want to undo the training?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [alert show];
}

- (IBAction)editAction:(id)sender
{
//    BOOL isEditing = self.descriptionTableView.isEditing;
//    [self.descriptionTableView setEditing:!isEditing animated:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Ok"]) {
        self.svmClassifier = self.previousSvmClassifier;
        self.undoButtonBar.enabled = NO;
        [self saveAction:self];
        [self loadDetectorInfo];
    }
}




#pragma mark -
#pragma mark SendingViewDelegate

- (void) cancel
{
    self.sendingView.hidden = YES;
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark -
#pragma mark ClassifierDelegate


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
#pragma mark ModalTVCDelegate

- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;
{
    if([identifier isEqualToString:@"Select Class"]){
        NSNumber *sel = [selectedItems objectAtIndex:0];
        self.svmClassifier.targetClass = [self.availableObjectClasses objectAtIndex:sel.intValue];
        self.svmClassifier.name = [NSString stringWithFormat:@"%@%@",self.svmClassifier.targetClass, [self uuid]];
        
    }else if([identifier isEqualToString:@"Select Training Images"]){
        
        //not first training any more
        self.firstTraingState = NOT_FIRST;
        
        //split train and test
        NSMutableArray *traingImagesNames = [[NSMutableArray alloc] init];
        NSMutableArray *testImagesNames = [[NSMutableArray alloc]init];
        for(int i=0;i<self.availablePositiveImagesNames.count;i++){
            NSUInteger index = [selectedItems indexOfObject:[NSNumber numberWithInt:i]];
            if(index != NSNotFound) [traingImagesNames addObject:[self.availablePositiveImagesNames objectAtIndex:i]];
            else [testImagesNames addObject:[self.availablePositiveImagesNames objectAtIndex:i]];
        }
        if(testImagesNames.count == 0) testImagesNames = traingImagesNames;
        
        //SENDING VIEW initialization
        self.sendingView.progressView.hidden = NO;
        [self.sendingView.progressView setProgress:0 animated:YES];
        self.sendingView.hidden = NO;
        self.navigationController.navigationBarHidden = YES;
        [self.sendingView.activityIndicator startAnimating];
        self.sendingView.cancelButton.hidden = YES;

        //set hog dimension based on user preferences
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[self.resourcesPaths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
        int hog = [(NSNumber *)[dict objectForKey:@"hogdimension"] intValue];
        if(hog==0) hog = 4; //minimum hog
        self.svmClassifier.maxHog = hog;
        
        //train in a different thread
        dispatch_queue_t myQueue = dispatch_queue_create("learning_queue", 0);
        dispatch_async(myQueue, ^{
            [self trainForImagesNames:traingImagesNames];
            if(self.trainingWentGood)[self testForImagesNames:testImagesNames];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.sendingView.activityIndicator stopAnimating];
                self.sendingView.cancelButton.hidden = NO;
                if(self.trainingWentGood) {[self saveAction:self]; [self loadDetectorInfo];}
                else {
                    self.navigationController.navigationBarHidden = NO;
                    [self.navigationController popViewControllerAnimated:YES];
                }
            });
        });
    }
}

- (void) selectionCancelled
{
    if(self.firstTraingState != NOT_FIRST) self.firstTraingState = INTERRUPTED;
}


#pragma mark -
#pragma mark Memory Management

-(void) didReceiveMemoryWarning
{
    NSLog(@"Memory warning received!!!");
    [super didReceiveMemoryWarning];
}



#pragma mark -
#pragma mark Table View

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return self.classifierProperties.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSDictionary *property = [self.classifierProperties objectAtIndex:indexPath.row];
    NSString *propertyName = [[property allKeys] objectAtIndex:0];
    if([propertyName isEqualToString:@"Name"]){
        NSString * const kCellID = @"editableCell";
        EditableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: kCellID];
        if(!cell) cell = [[EditableTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier: kCellID];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = propertyName;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor colorWithWhite:.8 alpha:.2];
        cell.textField.placeholder = [property objectForKey:propertyName];
        cell.textField.delegate = self;
        cell.textField.returnKeyType = UIReturnKeyDone;
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.text = [property objectForKey:propertyName];
        return cell;
    
    }else{
        static NSString *MyIdentifier = @"DetectorDescriptionTableCell";
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:MyIdentifier];
        if (cell == nil)cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2  reuseIdentifier:MyIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textLabel.text = propertyName;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.text = [property objectForKey:propertyName];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor colorWithWhite:.8 alpha:.2];

        return cell;
    }
    
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
#pragma mark UITextFieldDelegate

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSString *text = [[textField text] stringByReplacingCharactersInRange:range withString:string];
	NSIndexPath *indexPath = [self.descriptionTableView indexPathForFirstResponder];
	UITableViewCell *cell = [self.descriptionTableView cellForRowAtIndexPath:indexPath];
    
	if([cell.textLabel.text isEqualToString:@"Name"]) self.svmClassifier.name = text;
    
	return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self.delegate updateDetector:self.svmClassifier];
    [textField resignFirstResponder];
    self.classifierProperties = nil;
    self.title = self.svmClassifier.name;
    [self.descriptionTableView reloadData];
	return YES;
}

#pragma mark -
#pragma mark Private methods


-(void) trainForImagesNames:(NSArray *)imagesNames
{
    //initialization
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    self.svmClassifier.imagesUsedTraining = [[NSMutableArray alloc] init];
    
    //training set construction
    for(NSString *imageName in imagesNames){
        BOOL containedClass = NO;
        NSString *objectsPath = [(NSString *)[self.resourcesPaths objectAtIndex:OBJECTS]  stringByAppendingPathComponent:imageName];
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:objectsPath]];
        for(Box *box in objects){
            if([box.label isEqualToString:self.svmClassifier.targetClass]){ //add bounding box
                containedClass = YES;
                BoundingBox *cp = [[BoundingBox alloc] init];
                cp.xmin = box.upperLeft.x/box->RIGHTBOUND;
                cp.ymin = box.upperLeft.y/box->LOWERBOUND;
                cp.xmax = box.lowerRight.x/box->RIGHTBOUND;
                cp.ymax = box.lowerRight.y/box->LOWERBOUND;
                cp.imageIndex = trainingSet.images.count;
                cp.label = 1;
                [trainingSet.groundTruthBoundingBoxes addObject:cp];
            }
        }
        if(containedClass){ //add image
            NSString *imagePath = [(NSString *)[self.resourcesPaths objectAtIndex:IMAGES]  stringByAppendingPathComponent:imageName];
            UIImage *image = [[UIImage alloc]initWithContentsOfFile:imagePath];
            [trainingSet.images addObject:image];
            [self.svmClassifier.imagesUsedTraining addObject:imageName];
        }
    }
    
    //Add abstract pictures to the training set to generate false positives when the bb is very big
    //guess the relationship with the artists :)
    [trainingSet.images addObject:[UIImage imageNamed:@"picaso.jpg"]];
    [trainingSet.images addObject:[UIImage imageNamed:@"dali.jpg"]];
    [trainingSet.images addObject:[UIImage imageNamed:@"miro.jpg"]];
    
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images in the training set: %d",trainingSet.images.count]];
        
    //obtain the image average of the groundtruth images 
    NSMutableArray *listOfImages = [[NSMutableArray alloc] initWithCapacity:trainingSet.boundingBoxes.count];
    for(BoundingBox *cp in trainingSet.groundTruthBoundingBoxes){
        UIImage *wholeImage = [trainingSet.images objectAtIndex:cp.imageIndex];
        UIImage *croppedImage = [wholeImage croppedImage:[cp rectangleForImage:wholeImage]];
        [listOfImages addObject:[croppedImage resizedImage:trainingSet.templateSize interpolationQuality:kCGInterpolationLow]];
    }
    self.averageImage = [self imageAveraging:listOfImages];
    self.detectorView.image = self.averageImage;
    

    //learn
    [self updateProgress:0.05];
    [self.sendingView showMessage:@"Training begins!"];
    int successTraining = [self.svmClassifier train:trainingSet];
    dispatch_sync(dispatch_get_main_queue(), ^{
        if(!successTraining){
            self.trainingWentGood = NO;
            [self.sendingView showMessage:@"Error training"];
            
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error Training"
                                                                     message:@"Shape on training set not allowed.\n Make sure all the labels have a similar shape and that are not too big."
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                [errorAlert show];
            
            
        }else{
            self.trainingWentGood = YES;
            [self.sendingView showMessage:@"Finished training"];
            [self updateProgress:1];
            
            //update view of the detector
            if(self.previousSvmClassifier != nil) self.undoButtonBar.enabled = YES;
        }
    });
}


- (void) testForImagesNames: (NSArray *) imagesNames
{
    //initialization
    TrainingSet *testSet = [[TrainingSet alloc] init];
    
    //training set construction
    for(NSString *imageName in imagesNames){
        BOOL containedClass = NO;
        NSString *objectsPath = [(NSString *)[self.resourcesPaths objectAtIndex:OBJECTS]  stringByAppendingPathComponent:imageName];
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:objectsPath]];
        for(Box *box in objects){
            if([box.label isEqualToString:self.svmClassifier.targetClass]){ //add bounding box
                containedClass = YES;
                BoundingBox *cp = [[BoundingBox alloc] init];
                cp.xmin = box.upperLeft.x/box->RIGHTBOUND;
                cp.ymin = box.upperLeft.y/box->LOWERBOUND;
                cp.xmax = box.lowerRight.x/box->RIGHTBOUND;
                cp.ymax = box.lowerRight.y/box->LOWERBOUND;
                cp.imageIndex = testSet.images.count;
                cp.label = 1;
                [testSet.groundTruthBoundingBoxes addObject:cp];
            }
        }
        if(containedClass){ //add image
            NSString *imagePath = [(NSString *)[self.resourcesPaths objectAtIndex:IMAGES]  stringByAppendingPathComponent:imageName];
            UIImage *image = [[UIImage alloc]initWithContentsOfFile:imagePath];
            [testSet.images addObject:image];
        }
    }
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images in the test set: %d",testSet.images.count]];
    [self.sendingView showMessage:@"Testing begins!"];
    [self.svmClassifier testOnSet:testSet atThresHold:0.0];
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

-(UIImage *) imageAveraging:(NSArray *) images
{    
    CGImageRef imageRef = [(UIImage *)[images objectAtIndex:0] CGImage];
    NSUInteger width = CGImageGetWidth(imageRef); //#pixels width
    NSUInteger height = CGImageGetHeight(imageRef); //#pixels height
    UInt8 *imageResult = (UInt8 *) calloc(height*width*4,sizeof(UInt8));
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * width;
    int bitsPerComponent = 8;
    
    
    for(UIImage *image in images){
        
        //obtain pixels per image
        CGImageRef imageRef = image.CGImage;
        UInt8 *imagePointer = (UInt8 *) calloc(height * width * 4, sizeof(UInt8)); //4 channels
        CGContextRef contextImage = CGBitmapContextCreate(imagePointer, width, height, bitsPerComponent, bytesPerRow, CGColorSpaceCreateDeviceRGB(),kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(contextImage, CGRectMake(0, 0, width, height), imageRef);
        CGContextRelease(contextImage);
        
        //average
        for(int i=0; i<height*width*4; i++)
            imageResult[i] += imagePointer[i]*1.0/images.count;
    }
    
    //enhancement: increase contrast by ajusting max and min to 255 and 0 respectively
    int max=0, min=255;
    for(int i=0; i<height*width*4; i++){
        max = imageResult[i]>max ? imageResult[i]:max;
        min = imageResult[i]<min ? imageResult[i]:min;
    }
    
    for(int i=0; i<height*width*4; i++)
        imageResult[i] = (imageResult[i]-min)*(255/(max-min));
    
    //construct final image
    CGContextRef contextResult = CGBitmapContextCreate(imageResult, width, height, 8, 4*width,
                                                 CGColorSpaceCreateDeviceRGB(),kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef imageResultRef = CGBitmapContextCreateImage(contextResult);
    CGContextRelease(contextResult);
    UIImage *image = [UIImage imageWithCGImage:imageResultRef scale:1.0 orientation:UIImageOrientationUp];
    return image;
}

- (void) loadDetectorInfo
{
    
    //images
    self.detectorHogView.image = [UIImage hogImageFromFeatures:self.svmClassifier.weightsP withSize:self.svmClassifier.sizesP];
    self.detectorView.image = [UIImage imageWithContentsOfFile:self.svmClassifier.averageImagePath];
    
    self.classifierProperties = nil;
    [self.descriptionTableView reloadData];
    [self.view setNeedsDisplay];
}


- (IBAction)saveAction:(id)sender
{
    //save average image
    NSString *pathDetectorsBig = [[self.resourcesPaths objectAtIndex:DETECTORS ] stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"%@_big.jpg",self.svmClassifier.name]];
    self.detectorView.image = self.averageImage;
    [[NSFileManager defaultManager] createFileAtPath:pathDetectorsBig contents:UIImageJPEGRepresentation(self.averageImage, 1.0) attributes:nil];
    self.svmClassifier.averageImagePath = pathDetectorsBig;
    
    //save average image thumbnail
    NSString *pathDetectorsThumb = [[self.resourcesPaths objectAtIndex:DETECTORS ] stringByAppendingPathComponent:
                                    [NSString stringWithFormat:@"%@_thumb.jpg",self.svmClassifier.name]];
    [[NSFileManager defaultManager] createFileAtPath:pathDetectorsThumb contents:UIImageJPEGRepresentation([self.averageImage thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil];
    self.svmClassifier.averageImageThumbPath = pathDetectorsThumb;
    self.svmClassifier.updateDate = [NSDate date];
    
    [self loadDetectorInfo];
    [self.delegate updateDetector:self.svmClassifier];
}

- (void)viewDidUnload {
    [self setDescriptionTableView:nil];
    [self setScrollView:nil];
    [self setShowView:nil];
    [self setShowView:nil];
    [super viewDidUnload];
}
@end
