//
//  DetectirDescriptionViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorDescriptionViewController.h"
#import "Classifier.h"
#import "Box.h"
#import "ConvolutionHelper.h"

#import "UIImage+Resize.h"
#import "UIImage+HOG.h"


@implementation DetectorDescriptionViewController

@synthesize executeController = _executeController;
@synthesize trainingSetController = _trainingSetController;
@synthesize sendingView = _sendingView;
@synthesize svmClassifier = _svmClassifier;
@synthesize executeButton = _executeButton;
@synthesize userPath = _userPath;
@synthesize classTextField = _classTextField;
@synthesize delegate = _delegate;
@synthesize averageImage = _averageImage;


#pragma mark
#pragma mark - Life cycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //load views
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    self.trainingSetController = [[ShowTrainingSetViewController alloc] initWithNibName:@"ShowTrainingSetViewController" bundle:nil];
    
    //set labels
    self.classTextField.text = self.svmClassifier.targetClass;
    self.nameTextField.text = self.svmClassifier.name;
    self.detectorView.contentMode = UIViewContentModeScaleAspectFit;
    
    //Check if the classifier exists.
    if([self.svmClassifier.targetClass isEqualToString:@"Not Set"]){
        NSLog(@"No classifier");
        self.executeButton.enabled = NO;
        self.executeButton.alpha = 0.6f;
        
    }else{
        NSLog(@"Loading classifier");
        self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.svmWeights withSize:self.svmClassifier.weightsDimensions];
        self.saveButton.enabled = NO;
        self.saveButton.alpha = 0.6f;
    }
    
    //set editing button
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.nameTextField.enabled = NO;
    self.classTextField.enabled = NO;
    self.saveButton.enabled = NO;
    self.saveButton.alpha = 0.6f;
    
    //sending view, responsible for the waiting view
    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    self.sendingView.delegate = self;
    
    self.sendingView.hidden = YES;
    self.sendingView.progressView.hidden = YES;
    self.sendingView.label.numberOfLines = 0;
    self.sendingView.label.frame =  CGRectMake(20,100,300,200);
                                              
    NSLog(@"%f, %f, %f",self.sendingView.activityIndicator.frame.origin.x + self.sendingView.activityIndicator.frame.size.width + 10,
          self.sendingView.activityIndicator.frame.origin.y-100,
          (self.sendingView.progressView.frame.size.width - self.sendingView.activityIndicator.frame.size.width));
    [self.view addSubview:self.sendingView];
    
}



- (void)viewDidUnload
{
    [self setExecuteButton:nil];
    [self setDetectorView:nil];
    [self setTrainButton:nil];
    [self setSaveButton:nil];
    [self setClassTextField:nil];
    [self setNameTextField:nil];
    [self setSendingView:nil];
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

#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define MAX_IMAGE_SIZE 300
#define IMAGE_SCALE_FACTOR 0.6




-(void) train
{
    //retrive all images containing classToLearn
    NSString *selectedClass = self.svmClassifier.targetClass;
    
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    
    //get the path
    NSArray *resourcesPaths = [NSArray arrayWithObjects:[self.userPath stringByAppendingPathComponent:@"images"],[self.userPath stringByAppendingPathComponent:@"thumbnail"],[self.userPath stringByAppendingPathComponent:@"annotations"],self.userPath, nil];
    
    //get items
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSArray *imagesList = [filemng contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[resourcesPaths objectAtIndex:THUMB]] error:NULL];
    
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


#pragma mark
#pragma mark - Editing mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated
{
    [super setEditing:flag animated:animated];
    if (flag == YES){
        // Change views to edit mode.
        NSLog(@"Now editing!");
        self.classTextField.enabled = YES;
        self.nameTextField.enabled = YES;
        
    }else {
        // Save the changes if needed and change the views to noneditable.
        NSLog(@"End editing");
        self.svmClassifier.name = self.nameTextField.text;
        self.svmClassifier.targetClass = self.classTextField.text;
        self.title = self.nameTextField.text;
        self.classTextField.enabled = NO;
        self.nameTextField.enabled = YES;
        [self.delegate updateDetector:self.svmClassifier];
    }
}


#pragma mark
#pragma mark - SendingViewDelegate

- (void) cancel
{
    
}


@end
