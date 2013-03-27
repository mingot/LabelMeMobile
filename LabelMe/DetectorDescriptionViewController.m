//
//  DetectirDescriptionViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorDescriptionViewController.h"
#import "Classifier.h"



@interface DetectorDescriptionViewController()

//return pointer to template from filename
- (double *) readTemplate:(NSString *)filename;

@end


@implementation DetectorDescriptionViewController

@synthesize trainController = _trainController;
@synthesize executeController = _executeController;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.trainController = [[TrainDetectorViewController alloc] initWithNibName:@"TrainDetectorViewController" bundle:nil];
    self.executeController = [[ExecuteDetectorViewController alloc] initWithNibName:@"ExecuteDetectorViewController" bundle:nil];
    // Do any additional setup after loading the view from its nib.
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
    self.executeController.svmClassifier = [[Classifier alloc] initWithTemplateWeights:[self readTemplate:@"bottle"]];
    [self.navigationController pushViewController:self.executeController animated:YES];
}



#pragma mark
#pragma mark - Private methods

- (double *) readTemplate:(NSString *)filename
{
//    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *path = [NSString stringWithFormat:@"%@/Templates/%@",documentsDirectory,filename];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
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

@end
