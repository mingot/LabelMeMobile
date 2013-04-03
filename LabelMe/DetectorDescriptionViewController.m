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


#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define MAX_IMAGE_SIZE 300
#define IMAGE_SCALE_FACTOR 0.6

@implementation DetectorDescriptionViewController

@synthesize executeController = _executeController;
@synthesize trainingSetController = _trainingSetController;
@synthesize modalTVC = _modalTVC;
@synthesize sendingView = _sendingView;
@synthesize svmClassifier = _svmClassifier;
@synthesize executeButton = _executeButton;
@synthesize userPath = _userPath;
@synthesize delegate = _delegate;
@synthesize averageImage = _averageImage;
@synthesize availableObjectClasses = _availableObjectClasses;
@synthesize targetClassButton = _targetClassButton;



- (NSArray *) availableObjectClasses
{
    if(!_availableObjectClasses){
        
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        NSArray *resourcesPaths = [NSArray arrayWithObjects:[self.userPath stringByAppendingPathComponent:@"images"],[self.userPath stringByAppendingPathComponent:@"thumbnail"],[self.userPath stringByAppendingPathComponent:@"annotations"],self.userPath, nil];
        NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[resourcesPaths objectAtIndex:THUMB]] error:NULL];
        
        for(int i=0; i<imagesList.count; i++){
            
            NSString *path = [[resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[imagesList objectAtIndex:i]];
            NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
            for(Box *box in objects)
                if([list indexOfObject:box.label] == NSNotFound)
                    [list addObject:box.label];

        }
        
        _availableObjectClasses = [[NSArray alloc] initWithArray:list];
    }
    
    return _availableObjectClasses;
}



#pragma mark
#pragma mark - Life cycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.svmClassifier.delegate = self;
    
    //load views
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    self.trainingSetController = [[ShowTrainingSetViewController alloc] initWithNibName:@"ShowTrainingSetViewController" bundle:nil];
    
    self.modalTVC = [[ModalTVC alloc] init];
    self.modalTVC.delegate = self;
    
    //set labels
    self.targetClassButton.titleLabel.text = self.svmClassifier.targetClass;
    self.nameTextField.text = self.svmClassifier.name;
    self.detectorView.contentMode = UIViewContentModeScaleAspectFit;
    
    //Check if the classifier exists.
    if([self.svmClassifier.targetClass isEqualToString:@"Not Set"]){
        NSLog(@"No classifier");
        self.executeButton.enabled = NO;
        self.executeButton.alpha = 0.6f;
//        self.targetClassButton.titleLabel.text = @"Not Set";
        [self.targetClassButton setTitle:@"Not Set" forState:UIControlStateNormal];
        
    }else{
        NSLog(@"Loading classifier");
        self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.svmWeights withSize:self.svmClassifier.weightsDimensions];
        self.saveButton.enabled = NO;
        self.saveButton.alpha = 0.6f;
//        self.targetClassButton.titleLabel.text = self.svmClassifier.targetClass;
        [self.targetClassButton setTitle:self.svmClassifier.targetClass forState:UIControlStateNormal];
    }
    
    //set buttons
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.nameTextField.enabled = NO;
    self.targetClassButton.enabled = NO;
    self.saveButton.enabled = NO;
    self.saveButton.alpha = 0.6f;
    
    //sending view, responsible for the waiting view
    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    self.sendingView.delegate = self;
    self.sendingView.hidden = YES;
    self.sendingView.progressView.hidden = YES;
    self.sendingView.label.numberOfLines = 0;
    self.sendingView.label.frame = CGRectMake(20,20,300,400);
    self.sendingView.label.font = [UIFont fontWithName:@"AmericanTypewriter" size:10];
    [self.view addSubview:self.sendingView];
    
}



- (void)viewDidUnload
{
    [self setExecuteButton:nil];
    [self setDetectorView:nil];
    [self setTrainButton:nil];
    [self setSaveButton:nil];
    [self setNameTextField:nil];
    [self setSendingView:nil];
    [self setTargetClassButton:nil];
    [super viewDidUnload];
}

#pragma mark
#pragma mark - Actions

- (IBAction)executeAction:(id)sender
{
    NSLog(@"Execute detector");
    self.executeController.svmClassifier = self.svmClassifier;
    [self.navigationController pushViewController:self.executeController animated:YES];
}


-(void) train
{
    //retrive all images containing classToLearn
    NSString *selectedClass = self.svmClassifier.targetClass;
    
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    
    //get the path
    NSArray *resourcesPaths = [NSArray arrayWithObjects:[self.userPath stringByAppendingPathComponent:@"images"],[self.userPath stringByAppendingPathComponent:@"thumbnail"],[self.userPath stringByAppendingPathComponent:@"annotations"],self.userPath, nil];
    
    //get items
    NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[resourcesPaths objectAtIndex:THUMB]] error:NULL];
    
    for(int i=0; i<imagesList.count; i++){

        [self.sendingView showMessage:[NSString stringWithFormat:@"IMAGE %d",i]];
    
        NSString *path = [[resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[imagesList objectAtIndex:i]];
        
        //image
        UIImage *img = [[UIImage alloc]initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[resourcesPaths objectAtIndex:IMAGES],[imagesList objectAtIndex:i]]];
        
        //dictionaries
        BOOL containClass = NO;
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
        for(Box *box in objects){
            if([box.label isEqualToString:selectedClass]){
                containClass = YES;
                ConvolutionPoint *cp = [[ConvolutionPoint alloc] init];
                cp.xmin = box.upperLeft.x/box->RIGHTBOUND;
                cp.ymin = box.upperLeft.y/box->LOWERBOUND;
                cp.xmax = box.lowerRight.x/box->RIGHTBOUND;
                cp.ymax = box.lowerRight.y/box->LOWERBOUND;
                cp.imageIndex = trainingSet.images.count;
                cp.label = 1;
                [trainingSet.groundTruthBoundingBoxes addObject:cp];
            }
        }
        if(containClass) [trainingSet.images addObject:[img scaleImageTo:IMAGE_SCALE_FACTOR]];
        
    }
    
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images in the training set: %d",trainingSet.images.count]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of boxes: %d", trainingSet.groundTruthBoundingBoxes.count]];
    
    
    [trainingSet initialFill];
    
    NSMutableArray *listOfImages = [[NSMutableArray alloc] initWithCapacity:trainingSet.boundingBoxes.count];
    
    for(int i=0; i<trainingSet.boundingBoxes.count; i++){
        ConvolutionPoint *cp = [trainingSet.boundingBoxes objectAtIndex:i];
        UIImage *wholeImage = [trainingSet.images objectAtIndex:cp.imageIndex];
        UIImage *croppedImage = [wholeImage croppedImage:[cp rectangleForImage:wholeImage]];
        [listOfImages addObject:[croppedImage resizedImage:trainingSet.templateSize interpolationQuality:kCGInterpolationDefault]];
    }
    
    
    //Image averaging
    CIFilter *filter = [CIFilter filterWithName:@"CIOverlayBlendMode"];
    CIImage *result = [[CIImage alloc] initWithImage:[listOfImages objectAtIndex:0]];
    for(int i=1;i<trainingSet.groundTruthBoundingBoxes.count;i++){
        CIImage *image = [[CIImage alloc] initWithImage:[listOfImages objectAtIndex:i]];
        [filter setValue:image forKey:@"inputImage"];
        [filter setValue:result forKey:@"inputBackgroundImage"];
        result = [filter valueForKey:kCIOutputImageKey];
    }
    self.detectorView.contentMode = UIViewContentModeScaleAspectFit;
    self.detectorView.image = [UIImage imageWithCIImage:result];
    
    //output the initial training images
    //self.trainingSetController.listOfImages = listOfImages;
    //self.trainingSetController.listOfImages = trainingSet.images;
    //[self.navigationController pushViewController:self.trainingSetController animated:YES];
    
    //learn
    [self.sendingView showMessage:@"Training begins!"];
    [self.svmClassifier train:trainingSet];
    [self.sendingView showMessage:@"Finished training"];

    //update view of the detector
    //self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.svmWeights withSize:self.svmClassifier.weightsDimensions];
    self.executeButton.enabled = YES;
    self.executeButton.alpha = 1.0f;
    self.saveButton.enabled = YES;
    self.saveButton.alpha = 1.0f;    
    self.sendingView.hidden = YES;
    [self.sendingView.activityIndicator stopAnimating];

}


- (IBAction)trainAction:(id)sender
{
    self.sendingView.hidden = NO;
    [self.sendingView.activityIndicator startAnimating];
    self.sendingView.cancelButton.hidden = YES;
    dispatch_queue_t myQueue = dispatch_queue_create("learning_queue", 0);
    dispatch_async(myQueue, ^{
        [self train];
    });
}


- (IBAction)saveAction:(id)sender
{
    [self.delegate updateDetector:self.svmClassifier];
    self.saveButton.enabled = NO;
    self.saveButton.alpha = 0.6f;
}

- (IBAction)infoAction:(id)sender
{
    self.sendingView.hidden = NO;
    self.sendingView.cancelButton.hidden = NO;
    self.sendingView.cancelButton.titleLabel.text = @"Done";
    [self.sendingView.messagesStack removeAllObjects];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Detector %@ for class %@", self.svmClassifier.name, self.svmClassifier.targetClass]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of Support Vectors:%@", self.svmClassifier.numberSV]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of positives %@", self.svmClassifier.numberOfPositives]];
    [self.sendingView showMessage:@"**** Results on the training set ****"];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Precision:%@",[self.svmClassifier.precisionRecall objectAtIndex:0]]];
    [self.sendingView showMessage:[NSString stringWithFormat:@"Recall:%@", [self.svmClassifier.precisionRecall objectAtIndex:1]]];
}

- (IBAction)showClass:(id)sender
{
    self.modalTVC.multipleChoice = NO;
    self.modalTVC.data = self.availableObjectClasses;
    [self presentModalViewController:self.modalTVC animated:YES];
}


#pragma mark
#pragma mark - Editing mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated
{
    [super setEditing:flag animated:animated];
    if (flag == YES){
        // Change views to edit mode.
        NSLog(@"Now editing!");
        self.targetClassButton.enabled = YES;
        self.nameTextField.enabled = YES;
        
    }else {
        // Save the changes if needed and change the views to noneditable.
        NSLog(@"End editing");
        self.svmClassifier.name = self.nameTextField.text;
        self.title = self.nameTextField.text;
        self.targetClassButton.enabled = NO;
        self.nameTextField.enabled = YES;
        [self.delegate updateDetector:self.svmClassifier];
    }
}


#pragma mark
#pragma mark - SendingViewDelegate

- (void) cancel
{
    self.sendingView.hidden = YES;
}

#pragma mark
#pragma mark - ClassifierDelegate


-(void) sendMessage:(NSString *)message
{
    [self.sendingView showMessage:message];
}


#pragma mark
#pragma mark - ModalTVCDelegate

- (void) userSlection:(NSArray *)selectedItems;
{
    NSNumber *sel = [selectedItems objectAtIndex:0];
    self.svmClassifier.targetClass = [self.availableObjectClasses objectAtIndex:sel.intValue];
    NSLog(@"selected class:%@", self.svmClassifier.targetClass);
    self.targetClassButton.titleLabel.text = self.svmClassifier.targetClass;
}

@end
