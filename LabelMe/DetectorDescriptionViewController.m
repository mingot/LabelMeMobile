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

@interface DetectorDescriptionViewController()

-(void) trainForImagesNames:(NSArray *)imagesNames;

//generate a unique id
- (NSString *)uuid;

@end




@implementation DetectorDescriptionViewController


@synthesize delegate = _delegate;

@synthesize executeController = _executeController;
@synthesize trainingSetController = _trainingSetController;
@synthesize modalTVC = _modalTVC;
@synthesize sendingView = _sendingView;
@synthesize svmClassifier = _svmClassifier;
@synthesize executeButton = _executeButton;
@synthesize userPath = _userPath;

@synthesize availableObjectClasses = _availableObjectClasses;
@synthesize availablePositiveImagesNames = _availablePositiveImagesNames;
@synthesize selectedPositiveImageIndexes = _selectedPositiveImageIndexes;
@synthesize selectedPostiveImageNames = _selectedPostiveImageNames;





-(NSArray *) availablePositiveImagesNames
{
    if(!_availablePositiveImagesNames){
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.resourcesPaths objectAtIndex:THUMB]] error:NULL];
        
        for(NSString *imageName in imagesList){
            NSString *path = [[self.resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
            NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
            for(Box *box in objects)
                if([box.label isEqualToString:self.svmClassifier.targetClass])
                    [list addObject:imageName];
        }
        _availablePositiveImagesNames = [NSArray arrayWithArray:list];
    }
    
    return _availablePositiveImagesNames;
}
    

-(NSArray *) availableObjectClasses
{
    if(!_availableObjectClasses){
        NSMutableArray *list = [[NSMutableArray alloc] init];

        NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.resourcesPaths objectAtIndex:THUMB]] error:NULL];
        
        for(NSString *imageName in imagesList){
            NSString *path = [[self.resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
            NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
            for(Box *box in objects)
                if([list indexOfObject:box.label] == NSNotFound)
                    [list addObject:box.label];
        }
        
        _availableObjectClasses = [NSArray arrayWithArray:list];
    }
    
    return _availableObjectClasses;
}




#pragma mark
#pragma mark - Life cycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.svmClassifier.delegate = self;
    self.resourcesPaths = [NSArray arrayWithObjects:[self.userPath stringByAppendingPathComponent:@"images"],[self.userPath stringByAppendingPathComponent:@"thumbnail"],[self.userPath stringByAppendingPathComponent:@"annotations"],self.userPath, nil];
    
    //load views
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    self.trainingSetController = [[ShowTrainingSetViewController alloc] initWithNibName:@"ShowTrainingSetViewController" bundle:nil];
    
    //set labels
    self.targetClassLabel.text = self.svmClassifier.targetClass;
    self.nameTextField.text = self.svmClassifier.name;
    self.detectorView.contentMode = UIViewContentModeScaleAspectFit;
    
    //Check if the classifier exists.
    if(self.svmClassifier.weights == nil){
        NSLog(@"No classifier");
        self.executeButton.enabled = NO;
        self.executeButton.alpha = 0.6f;
        
        //show modal to select the target class
        self.modalTVC = [[ModalTVC alloc] init];
        self.modalTVC.delegate = self;
        self.modalTVC.modalTitle = @"Select Class";
        self.modalTVC.multipleChoice = NO;
        self.modalTVC.data = self.availableObjectClasses;
        [self presentModalViewController:self.modalTVC animated:YES];
        
    }else{
        NSLog(@"Loading classifier");
        self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.weightsP withSize:self.svmClassifier.sizesP];
        self.saveButton.enabled = NO;
        self.saveButton.alpha = 0.6f;
        [self.trainButton setTitle:@"Retrain" forState:UIControlStateNormal];
    }
    
    //set buttons
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.nameTextField.enabled = NO;
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
    [self setTargetClassLabel:nil];
    [self setTrainButton:nil];
    [super viewDidUnload];
}

#pragma mark
#pragma mark - Actions

- (IBAction)executeAction:(id)sender
{
    self.executeController.svmClassifier = self.svmClassifier;
    [self.navigationController pushViewController:self.executeController animated:YES];
}

- (IBAction)trainAction:(id)sender
{
    //show modal to select training positives for the selected class
    self.modalTVC = [[ModalTVC alloc] init];
    self.modalTVC.delegate = self;
    self.modalTVC.modalTitle = @"Training Images";
    self.modalTVC.multipleChoice = NO;
    self.availablePositiveImagesNames = nil; //to reset
    NSMutableArray *imagesList = [[NSMutableArray alloc] init];
    for(NSString *imageName in self.availablePositiveImagesNames){
        [imagesList addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[self.resourcesPaths objectAtIndex:THUMB],imageName]]];
        [self.modalTVC.selectedItems addObject:[NSNumber numberWithInt:(imagesList.count-1)]];
    }
    self.modalTVC.data = imagesList;
    [self.modalTVC.view setNeedsDisplay];
    [self presentModalViewController:self.modalTVC animated:YES];
    
    [self.trainButton setTitle:@"Retrain" forState:UIControlStateNormal];
    
    //let's wait for the modalTVCDelegate answer to begin the training
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


#pragma mark
#pragma mark - Editing mode

- (void)setEditing:(BOOL)flag animated:(BOOL)animated
{
    [super setEditing:flag animated:animated];
    if (flag == YES){
        // Change views to edit mode.
        NSLog(@"Now editing!");
        self.nameTextField.enabled = YES;
        
    }else {
        // Save the changes if needed and change the views to noneditable.
        NSLog(@"End editing");
        self.svmClassifier.name = self.nameTextField.text;
        self.title = self.nameTextField.text;
        self.nameTextField.enabled = YES;
        [self.view endEditing:YES];
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

- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;
{
    if([identifier isEqualToString:@"Select Class"]){
        NSNumber *sel = [selectedItems objectAtIndex:0];
        self.svmClassifier.targetClass = [self.availableObjectClasses objectAtIndex:sel.intValue];
        self.targetClassLabel.text = self.svmClassifier.targetClass;
        self.svmClassifier.name = [NSString stringWithFormat:@"%@%@",self.svmClassifier.targetClass, [self uuid]];
        self.nameTextField.text = self.svmClassifier.name;
        
        NSLog(@"selected class:%@", self.svmClassifier.targetClass);
        
    }else if([identifier isEqualToString:@"Training Images"]){
        
        NSLog(@"selected images index: %@", selectedItems);
        
        NSMutableArray *traingImagesNames = [[NSMutableArray alloc] init];
        for(NSNumber *imageIndex in selectedItems)
            [traingImagesNames addObject:[self.availablePositiveImagesNames objectAtIndex:imageIndex.intValue]];
        
        //show debug indicator on screen
        self.sendingView.hidden = NO;
        [self.sendingView.activityIndicator startAnimating];
        self.sendingView.cancelButton.hidden = YES;

        //train in a different thread
        dispatch_queue_t myQueue = dispatch_queue_create("learning_queue", 0);
        dispatch_async(myQueue, ^{
            free(self.svmClassifier.weightsP);
            free(self.svmClassifier.sizesP);
            [self trainForImagesNames:traingImagesNames];
        });
    }
}

#pragma mark
#pragma mark - Memory Management

-(void) didReceiveMemoryWarning
{
    NSLog(@"Memory warning received!!!");
    [super didReceiveMemoryWarning];
}


#pragma mark
#pragma mark - Private methods


-(void) trainForImagesNames:(NSArray *)imagesNames
{
    //training set construction
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    
    for(NSString *imageName in imagesNames){
        
        //dictionaries
        BOOL containedClass = NO;
        NSString *objectsPath = [(NSString *)[self.resourcesPaths objectAtIndex:OBJECTS]  stringByAppendingPathComponent:imageName];
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:objectsPath]];
        for(Box *box in objects){
            if([box.label isEqualToString:self.svmClassifier.targetClass]){
                //add bounding box
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
        
        if(containedClass){
            //add Image
            NSString *imagePath = [(NSString *)[self.resourcesPaths objectAtIndex:IMAGES]  stringByAppendingPathComponent:imageName];
            UIImage *image = [[UIImage alloc]initWithContentsOfFile:imagePath];
            [trainingSet.images addObject:[image scaleImageTo:IMAGE_SCALE_FACTOR]];
        }
    }
    
    [self.sendingView showMessage:[NSString stringWithFormat:@"Number of images in the training set: %d",trainingSet.images.count]];
    
    
    [trainingSet initialFill];
    
    //constructing intial set of cropped images for visualization and image averaging
    NSMutableArray *listOfImages = [[NSMutableArray alloc] initWithCapacity:trainingSet.boundingBoxes.count];
    for(BoundingBox *cp in trainingSet.boundingBoxes){
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
    //[self.navigationController pushViewController:self.trainingSetController animated:YES];
    
    //learn
    [self.sendingView showMessage:@"Training begins!"];
    [self.svmClassifier train:trainingSet];
    [self.sendingView showMessage:@"Finished training"];

    self.trainingSetController.listOfImages = self.svmClassifier.imageListAux;
    [self.navigationController pushViewController:self.trainingSetController animated:YES];
    
    //update view of the detector
    //self.detectorView.image = [UIImage hogImageFromFeatures:self.svmClassifier.weightsP withSize:self.svmClassifier.sizesP];
    self.executeButton.enabled = YES;
    self.executeButton.alpha = 1.0f;
    self.saveButton.enabled = YES;
    self.saveButton.alpha = 1.0f;
    self.sendingView.hidden = YES;
    [self.sendingView.activityIndicator stopAnimating];
}


- (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *result = (__bridge NSString *) uuidStringRef;
    return [result substringToIndex:8];
}

@end
