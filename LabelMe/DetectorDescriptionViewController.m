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


@protocol DetectorDescriptionViewControllerDelegate <NSObject>

- (void) updateDetector;

@end



@interface DetectorDescriptionViewController()

//return pointer to template from filename
- (double *) readClassifier;

//save the current classifier to the disk
- (void) storeClassifier;

@end


@implementation DetectorDescriptionViewController

@synthesize executeController = _executeController;
@synthesize trainingSetController = _trainingSetController;
@synthesize svmClassifier = _svmClassifier;
@synthesize classifierName = _classifierName;
@synthesize classToLearn = _classToLearn;
@synthesize executeButton = _executeButton;
@synthesize userPath = _userPath;
@synthesize classTextField = _classTextField;
@synthesize delegate = _delegate;


#pragma mark
#pragma mark - Life cycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //load views
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    self.trainingSetController = [[ShowTrainingSetViewController alloc] initWithNibName:@"ShowTrainingSetViewController" bundle:nil];
    
    //set labels
    self.classTextField.text = self.classToLearn;
    self.nameTextField.text = self.classifierName;
    
    
    
    //Check if the classifier exists.
    if([self readClassifier]){
        NSLog(@"Loading classifier");
        self.svmClassifier = [[Classifier alloc] initWithTemplateWeights:[self readClassifier]];
        self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.svmWeights withSize:self.svmClassifier.weightsDimensions];
        self.saveButton.enabled = NO;
        self.saveButton.alpha = 0.6f;
        
    }else{
        NSLog(@"No classifier");
        self.executeButton.enabled = NO;
        self.executeButton.alpha = 0.6f;
        self.svmClassifier = [[Classifier alloc] init];
    }
    
    //set editing button
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.nameTextField.enabled = NO;
    self.classTextField.enabled = NO;
    self.saveButton.enabled = NO;
    self.saveButton.alpha = 0.6f;
    
}


- (void)viewDidUnload
{
    [self setExecuteButton:nil];
    [self setDetectorView:nil];
    [self setTrainButton:nil];
    [self setSaveButton:nil];
    [self setClassTextField:nil];
    [self setNameTextField:nil];
    [super viewDidUnload];
}

#pragma mark
#pragma mark - Actions

- (IBAction)executeAction:(id)sender
{

    NSLog(@"Execute detector");
    //load the detector 
    self.executeController.svmClassifier = self.svmClassifier;
    [self.navigationController pushViewController:self.executeController animated:YES];
}


#define IMAGES 0
#define THUMB 1
#define OBJECTS 2

- (IBAction)trianAction:(id)sender
{
    //retrive all images containing classToLearn
    NSString *selectedClass = self.classToLearn;//@"bottle";
    
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    
    //get the path
    NSArray *resourcesPaths = [NSArray arrayWithObjects:[self.userPath stringByAppendingPathComponent:@"images"],[self.userPath stringByAppendingPathComponent:@"thumbnail"],[self.userPath stringByAppendingPathComponent:@"annotations"],self.userPath, nil];

    //get items
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSArray *imagesList = [filemng contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[resourcesPaths objectAtIndex:THUMB]] error:NULL];
    
    for(int i=0; i<imagesList.count; i++){
        NSLog(@"IMAGE %d", i);
        NSString *path = [[resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[imagesList objectAtIndex:i]];
        
        //image
        UIImage *img = [[UIImage alloc]initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[resourcesPaths objectAtIndex:IMAGES],[imagesList objectAtIndex:i]]];

        //dictionaries
        BOOL containClass = NO;
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
        for(Box *box in objects){
            NSLog(@"label:%@", box.label);
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
        if(containClass) [trainingSet.images addObject:img];
        
    }
    
    
    NSLog(@"Number of images in the training set: %d",trainingSet.images.count);
    NSLog(@"Number of boxes: %d", trainingSet.groundTruthBoundingBoxes.count);
    
 
//    //INITIAL FILL AND VISUALIZE IMAGES GENERATED
//
//    [trainingSet initialFill];
//    
//    NSMutableArray *listOfImages = [[NSMutableArray alloc] initWithCapacity:trainingSet.boundingBoxes.count];
//    
//    for(int i=0; i<trainingSet.boundingBoxes.count; i++)
//    {
//        ConvolutionPoint *cp = [trainingSet.boundingBoxes objectAtIndex:i];
//        UIImage *wholeImage = [trainingSet.images objectAtIndex:cp.imageIndex];
//        UIImage *croppedImage = [wholeImage croppedImage:[cp rectangleForImage:wholeImage]];
//        [listOfImages addObject:[croppedImage resizedImage:trainingSet.templateSize interpolationQuality:kCGInterpolationDefault]];
//    }
//    
//    
//    self.trainingSetController.listOfImages = listOfImages;
//    //    self.trainingSetController.listOfImages = self.trainingSet.images;
//    
//    [self.navigationController pushViewController:self.trainingSetController animated:YES];
    

    //learn
    NSLog(@"Training begins!");
    [self.svmClassifier train:trainingSet];
    NSLog(@"Finished training");
    
    //update view of the detector
    self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.svmWeights withSize:self.svmClassifier.weightsDimensions];
    self.executeButton.enabled = YES;
    self.executeButton.alpha = 1.0f;
    self.saveButton.enabled = YES;
    self.saveButton.alpha = 1.0f;
}

- (IBAction)saveAction:(id)sender
{
    [self storeClassifier];
    [self.delegate updateDetectorName:self.classifierName forClass:self.classToLearn];
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
    }
    else {
        // Save the changes if needed and change the views to noneditable.
        NSLog(@"End editing");
        self.classifierName = self.nameTextField.text;
        self.classToLearn = self.classTextField.text;
        self.title = self.nameTextField.text;
        self.classTextField.enabled = NO;
        self.nameTextField.enabled = YES;
        [self.delegate updateDetectorName:self.classifierName forClass:self.classToLearn];
    }
}


#pragma mark
#pragma mark - Private methods

- (double *) readClassifier
{
    NSString *classifierName = [NSString stringWithFormat:@"%@_%@",self.classifierName, self.classToLearn];
    NSString *path = [NSString stringWithFormat:@"%@/Detectors/%@",self.userPath,classifierName];
    
    if(!path)
        return nil;
    
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSArray *file = [content componentsSeparatedByString:@"\n"];
    
    double *r = malloc((file.count)*sizeof(double));
    for (int i=0; i<file.count; i++) {
        NSString *str = [file objectAtIndex:i];
        *(r+i) = [str doubleValue];
    }
    
    return r;
}

- (void) storeClassifier
{
    NSString *classifierName = [NSString stringWithFormat:@"%@_%@",self.classifierName, self.classToLearn];
    NSString *path = [NSString stringWithFormat:@"%@/Detectors/%@",self.userPath,classifierName];
    
    int totalNumFeatures = self.svmClassifier.weightsDimensions[0]*self.svmClassifier.weightsDimensions[1]*self.svmClassifier.weightsDimensions[2];
    
    NSMutableString *content = [NSMutableString stringWithCapacity:totalNumFeatures+4];
    [content appendFormat:@"%d\n",self.svmClassifier.weightsDimensions[0]];
    [content appendFormat:@"%d\n",self.svmClassifier.weightsDimensions[1]];
    [content appendFormat:@"%d\n",self.svmClassifier.weightsDimensions[2]];
    for (int i = 0; i<totalNumFeatures + 1; i++)
        [content appendFormat:@"%f\n",self.svmClassifier.svmWeights[i]];
    
    if([content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:NULL])
        NSLog(@"Write Detector Work!");
}

@end
