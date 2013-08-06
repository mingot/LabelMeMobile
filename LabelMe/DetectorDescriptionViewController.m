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
#import "UIViewController+ShowAlert.h"

#import "UITableView+TextFieldAdditions.h"
#import "CustomUITableViewCell.h"




//#define IMAGES 0
//#define THUMB 1
//#define OBJECTS 2
//#define DETECTORS 3
//#define USER 4

#define MAX_IMAGE_SIZE 300

//self.firstTrainingState
#define NOT_FIRST 0
#define INITIATED 1
#define INTERRUPTED 2

//training results
#define SUCCESS 1
#define INTERRUPTED 2 //and not trained
#define FAIL 0


@interface DetectorDescriptionViewController()
{
    SelectionHandler *_selectionHandler;
}


@property (strong, nonatomic) UIImage *averageImage;
@property int firstTraingState; //0: not first training, 1: first training initiated, 2: first training interrupted
@property BOOL isFirstTraining;


// wrapper to call the detector for training and testing
-(int) trainForImagesNames:(NSArray *)imagesNames;
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

//-(NSArray *) availablePositiveImagesNames
//{
//    //get the images for the selected class (self.svmClassifier.targetClass)
//    if(!_availablePositiveImagesNames){
//        NSMutableArray *list = [[NSMutableArray alloc] init];
//        
//        NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.resourcesPaths objectAtIndex:THUMB]] error:NULL];
//        
//        for(NSString *imageName in imagesList){
//            NSString *path = [[self.resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
//            NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
//            for(Box *box in objects)
//                for(NSString *targetClass in self.svmClassifier.targetClasses)
//                    if([box.label isEqualToString:targetClass] && [list indexOfObject:imageName]==NSNotFound)
//                            [list addObject:imageName];
//        }
//        _availablePositiveImagesNames = [NSArray arrayWithArray:list];
//    }
//    
//    return _availablePositiveImagesNames;
//}


- (NSMutableArray *) classifierProperties
{
    if(!_classifierProperties && self.svmClassifier.weights != nil){
        
        //nsdate treatment
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy - HH:mm"];
        [formatter setTimeZone:[NSTimeZone localTimeZone]]; //time zone
        
        _classifierProperties = [[NSMutableArray alloc] init];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:self.svmClassifier.name forKey:@"Name"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[self.svmClassifier.targetClasses componentsJoinedByString:@", "] forKey:@"Class"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[formatter stringFromDate:self.svmClassifier.updateDate] forKey:@"Last Train"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", self.svmClassifier.imagesUsedTraining.count] forKey:@"Images"]];
        
        //just shown on ipad
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", self.svmClassifier.numberSV.intValue] forKey:@"Number SV"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", self.svmClassifier.numberOfPositives.intValue] forKey:@"Number Positives"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"HOG Dimensions: %@ x %@",[self.svmClassifier.sizes objectAtIndex:0],[self.svmClassifier.sizes objectAtIndex:1] ] forKey:@"HOG dimensions"]];
        [_classifierProperties addObject:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%.2f seconds", self.svmClassifier.timeLearning.floatValue] forKey:@"Time Learning"]];
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
    
    
    _selectionHandler = [[SelectionHandler alloc] initWithViewController:self andDetecorResourceHandler:self.detectorResourceHandler];
    
    
//    self.resourcesPaths = [NSArray arrayWithObjects:
//                           [self.userPath stringByAppendingPathComponent:@"images"],
//                           [self.userPath stringByAppendingPathComponent:@"thumbnail"],
//                           [self.userPath stringByAppendingPathComponent:@"annotations"],
//                           [self.userPath stringByAppendingPathComponent:@"Detectors"],
//                           self.userPath, nil];
    
    self.scrollView.contentSize = self.showView.frame.size;
    
    //controllers
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    self.executeController.delegate = self;
    
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
    
    //bottom toolbar
    [self.bottomToolbar setBarStyle:UIBarStyleBlackOpaque];
    
    //description table view
    self.descriptionTableView.layer.cornerRadius = 10;
    self.descriptionTableView.backgroundColor = [UIColor clearColor];
    
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
    [self.bottomToolbar setItems:[NSArray arrayWithObjects:flexibleSpace,self.executeButtonBar,flexibleSpace,self.trainButtonBar, flexibleSpace, self.infoButtonBar,flexibleSpace,self.undoButtonBar,flexibleSpace,nil]];
    
    self.undoButtonBar.enabled = NO;

    //Check if the classifier exists.
    if(self.svmClassifier.weights == nil){
        NSLog(@"New classifier");
//        self.isFirstTraining = YES;
//        //show modal to select the target class
//        self.modalTVC = [[ModalTVC alloc] init];
//        self.modalTVC.showCancelButton = YES;
//        self.modalTVC.delegate = self;
//        self.modalTVC.modalTitle = @"New Detector";
//        self.modalTVC.modalSubtitle = @"1 of 2: select class(es)";
//        self.modalTVC.modalID = @"classes";
//        self.modalTVC.multipleChoice = YES;
//        self.modalTVC.data = self.availableObjectClasses;
//        self.modalTVC.doneButtonTitle = @"Create";
//        [self presentModalViewController:self.modalTVC animated:YES];
//        self.firstTraingState = INITIATED;
        [_selectionHandler addNewDetector];
        
    }else{
        NSLog(@"Loading classifier: %@", self.svmClassifier.name);
        self.isFirstTraining = NO;
    }
    
    
    //sending view, responsible for the waiting view
    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];//self.tabBarController.view.frame];
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
    self.executeController.svmClassifiers = [NSArray arrayWithObject:self.svmClassifier];
    self.executeController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.executeController animated:NO];
}

- (IBAction)trainAction:(id)sender
{
    
//    //show modal to select training positives for the selected class
//    self.modalTVC = [[ModalTVC alloc] init];
//    self.modalTVC.delegate = self;
//    if(self.firstTraingState == INITIATED){ //training for the first time
//        self.modalTVC.modalTitle = @"New Detector";
//        self.modalTVC.modalSubtitle = @"2 of 2: select training image(es)";
//    }else{
//        self.modalTVC.modalTitle = @"Train Detector";
//        self.modalTVC.modalSubtitle = @"1 of 1: select training images";
//        //storing the previous classifier using the nscoding for object copy
//        self.previousSvmClassifier = [[Classifier alloc] init];
//        self.previousSvmClassifier = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self.svmClassifier]];
//    }
//    self.modalTVC.doneButtonTitle = @"Train";
//    self.modalTVC.modalID = @"images";
//    self.modalTVC.multipleChoice = NO;
//    
////    self.availablePositiveImagesNames = nil; //to reset
//    NSArray *availablePositiveImagesNames = [self.detectorResourceHandler getImageNamesContainingClasses:self.svmClassifier.targetClasses];
//    
//    NSMutableArray *imagesList = [[NSMutableArray alloc] init];
//    for(NSString *imageName in availablePositiveImagesNames){
//        NSLog(@"imageName: %@", imageName);
//        [imagesList addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.resourcesPaths objectAtIndex:THUMB],imageName]]];
//        if(self.svmClassifier.imagesUsedTraining == nil || [self.svmClassifier.imagesUsedTraining indexOfObject:imageName]!= NSNotFound)
//            [self.modalTVC.selectedItems addObject:[NSNumber numberWithInt:(imagesList.count-1)]];
//    }
//    self.modalTVC.showCancelButton = YES;
//    self.modalTVC.data = imagesList;
//    [self.modalTVC.view setNeedsDisplay];
//    [self presentModalViewController:self.modalTVC animated:YES];

    [_selectionHandler selectTrainingImages];
    
    //let's wait for the modalTVCDelegate answer to begin the training
}




- (IBAction)infoAction:(id)sender
{
    self.navigationController.navigationBarHidden = YES;
    self.sendingView.sendingViewID = @"info";
    [self.sendingView.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
    self.sendingView.hidden = NO;
    self.sendingView.cancelButton.hidden = NO;
    self.sendingView.progressView.hidden = YES;
    self.sendingView.activityIndicator.hidden = YES;
    [self.sendingView clearScreen];
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



- (IBAction)saveAction:(id)sender
{
    [self.detectorResourceHandler saveDetector:self.svmClassifier withImage:self.averageImage];
    self.detectorView.image = self.averageImage;
        
    self.svmClassifier.updateDate = [NSDate date];
    
    [self loadDetectorInfo];
    [self.delegate updateClassifier:self.svmClassifier];
}


#pragma mark -
#pragma mark SelectionHandlerDelegate


- (void) trainDetectorForClasses:(NSArray *)classes
               andTrainingImages:(NSArray *)trainingImagesNames
                   andTestImages:(NSArray *)testImagesNames
{
    //TODO: check if correct
    if(self.svmClassifier.targetClasses == nil){ //first time training
        self.svmClassifier.targetClasses = classes;
        NSString *className = [self.svmClassifier.targetClasses componentsJoinedByString:@"+"];
        self.svmClassifier.name = [NSString stringWithFormat:@"%@-Detector",className];
        self.svmClassifier.classifierID = [NSString stringWithFormat:@"%@%@",className,[self uuid]];
    }
    
    
    //SENDING VIEW initialization
    self.sendingView.progressView.hidden = NO;
    [self.sendingView.progressView setProgress:0 animated:YES];
    self.sendingView.hidden = NO;
    self.navigationController.navigationBarHidden = YES;
    [self.sendingView.activityIndicator startAnimating];
    self.sendingView.cancelButton.hidden = NO;
    self.sendingView.sendingViewID = @"train";
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.sendingView.cancelButton setTitle:@"Cancelling..." forState:UIControlStateDisabled];
    [self.sendingView clearScreen];
    self.svmClassifier.trainCancelled = NO;
    
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
                if(self.previousSvmClassifier != nil) self.undoButtonBar.enabled = YES;
                [self saveAction:self];
                [self loadDetectorInfo];
                
            }else if(trainingState == FAIL){
                [self.sendingView showMessage:@"Error training"];
            
                [self showAlertWithTitle:@"Error Training" andDescription:@"Shape on training set not allowed.\n Make sure all the labels have a similar shape and that are not too big."];
                
                if(self.isFirstTraining){
                    self.navigationController.navigationBarHidden = NO;
                    [self.navigationController popViewControllerAnimated:YES];
                }
                
            }else if(trainingState == INTERRUPTED){
                //if classifier not even trained with one iteration(cancelled before) then rescue previous classifer (undo)
                self.svmClassifier = self.previousSvmClassifier;
                self.undoButtonBar.enabled = NO;
                if(self.isFirstTraining){
                    self.navigationController.navigationBarHidden = NO;
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            
            //stop sending view
            [self.sendingView.activityIndicator stopAnimating];
            [self.sendingView.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
            self.sendingView.sendingViewID = @"info";
            self.sendingView.cancelButton.enabled = YES;
            self.sendingView.cancelButton.hidden = NO;
        });
    });

}



- (Classifier *) currentDetector
{
    return self.svmClassifier;
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
    if([self.sendingView.sendingViewID isEqualToString:@"info"]){
        self.sendingView.hidden = YES;
        self.navigationController.navigationBarHidden = NO;
    }else if([self.sendingView.sendingViewID isEqualToString:@"train"]){
        self.svmClassifier.trainCancelled = YES;
        self.sendingView.cancelButton.enabled = NO;
        self.sendingView.sendingViewID = @"info";
    }
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

//- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;
//{
//    if([identifier isEqualToString:@"classes"]){
//        NSMutableArray *classes = [[NSMutableArray alloc] init];
//        for(NSNumber *sel in selectedItems)
//            [classes addObject:[self.availableObjectClasses objectAtIndex:sel.intValue]];
//        self.svmClassifier.targetClasses = [NSArray arrayWithArray:classes];
//        NSString *className = [self.svmClassifier.targetClasses componentsJoinedByString:@"+"];
//        self.svmClassifier.name = [NSString stringWithFormat:@"%@-Detector",className];
//        self.svmClassifier.classifierID = [NSString stringWithFormat:@"%@%@",className,[self uuid]];
//        
//    }else if([identifier isEqualToString:@"images"]){
//        
//        //not first training any more
//        self.firstTraingState = NOT_FIRST;
//        
//        //split train and test
//        NSMutableArray *traingImagesNames = [[NSMutableArray alloc] init];
//        NSMutableArray *testImagesNames = [[NSMutableArray alloc]init];
//        for(int i=0;i<self.availablePositiveImagesNames.count;i++){
//            NSUInteger index = [selectedItems indexOfObject:[NSNumber numberWithInt:i]];
//            if(index != NSNotFound) [traingImagesNames addObject:[self.availablePositiveImagesNames objectAtIndex:i]];
//            else [testImagesNames addObject:[self.availablePositiveImagesNames objectAtIndex:i]];
//        }
//        if(testImagesNames.count == 0) testImagesNames = traingImagesNames;
//        
//        //SENDING VIEW initialization
//        self.sendingView.progressView.hidden = NO;
//        [self.sendingView.progressView setProgress:0 animated:YES];
//        self.sendingView.hidden = NO;
//        self.navigationController.navigationBarHidden = YES;
//        [self.sendingView.activityIndicator startAnimating];
//        self.sendingView.cancelButton.hidden = NO;
//        self.sendingView.sendingViewID = @"train";
//        [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
//        [self.sendingView.cancelButton setTitle:@"Cancelling..." forState:UIControlStateDisabled];
//        [self.sendingView clearScreen];
//        self.svmClassifier.trainCancelled = NO;
//        
//        //train in a different queue
//        dispatch_queue_t myQueue = dispatch_queue_create("learning_queue", 0);
//        dispatch_async(myQueue, ^{
//            __block int trainingState = [self trainForImagesNames:traingImagesNames];
//            if (trainingState == SUCCESS) {
//                [self.sendingView showMessage:@"Finished training"];
//                [self testForImagesNames:testImagesNames];
//            }
//                
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                if(trainingState == SUCCESS){
//                    [self updateProgress:1];
//                    
//                    //update view of the detector
//                    if(self.previousSvmClassifier != nil) self.undoButtonBar.enabled = YES;
//                    [self saveAction:self];
//                    [self loadDetectorInfo];
//                    
//                }else if(trainingState == FAIL){
//                    [self.sendingView showMessage:@"Error training"];
//                    
//                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error Training"
//                                                                         message:@"Shape on training set not allowed.\n Make sure all the labels have a similar shape and that are not too big."
//                                                                        delegate:nil
//                                                               cancelButtonTitle:@"OK"
//                                                               otherButtonTitles:nil];
//                    [errorAlert show];
//                    
//                    if(self.isFirstTraining){
//                        self.navigationController.navigationBarHidden = NO;
//                        [self.navigationController popViewControllerAnimated:YES];
//                    }
//                    
//                }else if(trainingState == INTERRUPTED){
//                    //if classifier not even trained with one iteration(cancelled before) then rescue previous classifer (undo)
//                    self.svmClassifier = self.previousSvmClassifier;
//                    self.undoButtonBar.enabled = NO;
//                    if(self.isFirstTraining){
//                        self.navigationController.navigationBarHidden = NO;
//                        [self.navigationController popViewControllerAnimated:YES];
//                    }
//                }
//                    
//                //stop sending view
//                [self.sendingView.activityIndicator stopAnimating];
//                [self.sendingView.cancelButton setTitle:@"Done" forState:UIControlStateNormal];
//                self.sendingView.sendingViewID = @"info";
//                self.sendingView.cancelButton.enabled = YES;
//                self.sendingView.cancelButton.hidden = NO;
//            });
//        });
//    }
//}
//
//- (void) selectionCancelled
//{
//    if(self.firstTraingState != NOT_FIRST) self.firstTraingState = INTERRUPTED;
//}


#pragma mark -
#pragma mark ExecuteDetectorViewCotrollerDelegate

- (void) updateClassifier:(Classifier *)classifier
{
    //received when updating classifier threshold from execute controller
    [self.delegate updateClassifier:classifier];
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
    int orientation = [[UIDevice currentDevice] orientation];
    BOOL isIpad = [[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad;
    
//    if([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPad) return self.classifierProperties.count;
//    else return 4;
    
    if(isIpad && orientation == UIInterfaceOrientationPortrait) return self.classifierProperties.count;
    else if(isIpad) return 6;
    else if(!isIpad && orientation == UIInterfaceOrientationPortrait) return 4;
    else return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *property = [self.classifierProperties objectAtIndex:indexPath.row];
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
        if (!self.isFirstTraining) cell.textField.text = [property objectForKey:propertyName];
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
    [self.delegate updateClassifier:self.svmClassifier];
    self.isFirstTraining = NO;
    [textField resignFirstResponder];
    self.classifierProperties = nil;
    self.title = self.svmClassifier.name;
    [self.descriptionTableView reloadData];
	return YES;
}

#pragma mark -
#pragma mark Private methods


-(int) trainForImagesNames:(NSArray *)imagesNames
{
    //initialization
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    self.svmClassifier.imagesUsedTraining = [[NSMutableArray alloc] init];
    
    //setting hog dimensions based on user preferences
    int hog = [self.detectorResourceHandler getHogFromPreferences];
    self.svmClassifier.maxHog = hog;
    
    //training set construction
    for(NSString *imageName in imagesNames){
        BOOL containedClass = NO;
        
        NSMutableArray *objects = [_detectorResourceHandler getBoxesForImageName:imageName];
        
        for(Box *box in objects){
            for(NSString *class in self.svmClassifier.targetClasses)
                if([box.label isEqualToString:class]){ //add bounding box
                    containedClass = YES;
                    BoundingBox *cp = [[BoundingBox alloc] init];
                    cp.xmin = box.upperLeft.x/box.imageSize.width;
                    cp.ymin = box.upperLeft.y/box.imageSize.height;
                    cp.xmax = box.lowerRight.x/box.imageSize.width;
                    cp.ymax = box.lowerRight.y/box.imageSize.height;
                    cp.imageIndex = trainingSet.images.count;
                    cp.label = 1;
                    [trainingSet.groundTruthBoundingBoxes addObject:cp];
                }
        }
        if(containedClass){ //add image
            UIImage *image = [_detectorResourceHandler getImageWithImageName:imageName];
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
        UIImage *croppedImage = [wholeImage croppedImage:[[cp increaseSizeByFactor:0.2] rectangleForImage:wholeImage]]; //
        [listOfImages addObject:[croppedImage resizedImage:trainingSet.templateSize interpolationQuality:kCGInterpolationLow]];
    }
    self.averageImage = [self imageAveraging:listOfImages];
    self.detectorView.image = self.averageImage;
    

    //learn
    [self updateProgress:0.05];
    [self.sendingView showMessage:@"Training begins!"];
    int successTraining = [self.svmClassifier train:trainingSet];

    return successTraining;
}


- (void) testForImagesNames: (NSArray *) imagesNames
{
    //initialization
    TrainingSet *testSet = [[TrainingSet alloc] init];
    
    //training set construction
    for(NSString *imageName in imagesNames){
        BOOL containedClass = NO;

        NSMutableArray *objects = [_detectorResourceHandler getBoxesForImageName:imageName];
        
        for(Box *box in objects){
            for(NSString *class in self.svmClassifier.targetClasses)
                if([box.label isEqualToString:class]){ //add bounding box
                    containedClass = YES;
                    BoundingBox *cp = [[BoundingBox alloc] init];
                    cp.xmin = box.upperLeft.x/box.imageSize.width;
                    cp.ymin = box.upperLeft.y/box.imageSize.height;
                    cp.xmax = box.lowerRight.x/box.imageSize.width;
                    cp.ymax = box.lowerRight.y/box.imageSize.height;
                    cp.imageIndex = testSet.images.count;
                    cp.label = 1;
                    [testSet.groundTruthBoundingBoxes addObject:cp];
                }
        }
        if(containedClass){ //add image
            UIImage *image = [_detectorResourceHandler getImageWithImageName:imageName];
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

- (void)viewDidUnload {
    [self setDescriptionTableView:nil];
    [self setScrollView:nil];
    [self setShowView:nil];
    [self setShowView:nil];
    [super viewDidUnload];
}
@end
