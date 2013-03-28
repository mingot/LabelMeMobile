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


@interface DetectorDescriptionViewController()

//return pointer to template from filename
- (double *) readTemplate:(NSString *)filename;

@end


@implementation DetectorDescriptionViewController

@synthesize trainController = _trainController;
@synthesize executeController = _executeController;
@synthesize svmClassifier = _svmClassifier;
@synthesize classToLearn = _classToLearn;
@synthesize executeButton = _executeButton;



- (void)viewDidLoad
{
    [super viewDidLoad];
    self.trainController = [[TrainDetectorViewController alloc] initWithNibName:@"TrainDetectorViewController" bundle:nil];
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    
    //set labels
    self.classifierNameLabel.text = self.classifierName;
    self.classToLearnLabel.text = self.classToLearn;
    
    //Check if the classifier exists.
    if([self readTemplate:self.classifierName])
        self.svmClassifier = [[Classifier alloc] initWithTemplateWeights:[self readTemplate:self.classifierName]];
    else{
        [self.executeButton setEnabled:NO];
        NSLog(@"No classifier");
    }
    
    NSLog(@"VIEW DID LOAD!!!");
}


- (IBAction)trainAction:(id)sender
{
    NSLog(@"Train detector");
    //SET THE DELEGATE TO RETURN THE TRAINED CLASSIFIER
    self.trainController.trainingSet = [[TrainingSet alloc] init];
    [self.navigationController pushViewController:self.trainController animated:YES];
    
}

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

- (IBAction)trainFromSetAction:(id)sender
{
    //retrive all images containing classToLearn
    NSString *username = @"mingot";
    NSString *selectedClass = @"bottle";
    
    TrainingSet *trainingSet = [[TrainingSet alloc] init];
    
    //get the path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *userPath = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,username ];
    NSArray *resourcesPaths = [NSArray arrayWithObjects:[userPath stringByAppendingPathComponent:@"images"],[userPath stringByAppendingPathComponent:@"thumbnail"],[userPath stringByAppendingPathComponent:@"annotations"],userPath, nil];

    //get items
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSArray *selfItems = [filemng contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[resourcesPaths objectAtIndex:THUMB]] error:NULL];
    
    for(int i=0; i<selfItems.count; i++){
        NSLog(@"IMAGE %d", i);
        NSString *path = [[resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[selfItems objectAtIndex:i]];
        
        //image
        UIImage *img = [[UIImage alloc]initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[resourcesPaths objectAtIndex:IMAGES],[selfItems objectAtIndex:i]]];

        //dictionaries
        BOOL containClass = NO;
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
        for(Box *box in objects){
            NSLog(@"label:%@", box.label);
            if([box.label isEqualToString:selectedClass]){
                containClass = YES;
                ConvolutionPoint *cp = [[ConvolutionPoint alloc] init];
                cp.xmin = box.upperLeft.x/img.size.width;
                cp.ymin = box.upperLeft.y/img.size.height;
                cp.xmax = box.lowerRight.x/img.size.width;
                cp.ymax = box.lowerRight.y/img.size.height;
                cp.imageIndex = i;
                [trainingSet.groundTruthBoundingBoxes addObject:cp];
            }
        }
        if(containClass) [trainingSet.images addObject:img];
        
    }
    
    NSLog(@"Number of images in the training set: %d",trainingSet.images.count);
    NSLog(@"Number of boxes: %d", trainingSet.groundTruthBoundingBoxes.count);
    
    //initial fill
    [trainingSet initialFill];
    NSLog(@"Number of instances generated in training set: %d", trainingSet.images.count);
    
    
//    //learn
//    [self.svmClassifier train:trainingSet];
    
    //store classifier
    
}



#pragma mark
#pragma mark - Private methods

- (double *) readTemplate:(NSString *)filename
{
//    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *path = [NSString stringWithFormat:@"%@/Templates/%@",documentsDirectory,filename];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
    
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

- (void)viewDidUnload {
    [self setExecuteButton:nil];
    [self setClassifierNameLabel:nil];
    [self setClassToLearnLabel:nil];
    [super viewDidUnload];
}
@end
