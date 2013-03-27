//
//  DetectirDescriptionViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorDescriptionViewController.h"



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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)trainAction:(id)sender
{
    NSLog(@"Train detector");
}

- (IBAction)executeAction:(id)sender
{

    NSLog(@"Execute detector");
}

@end
