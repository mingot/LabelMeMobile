//
//  TrainDetectorViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#import "ShowTrainingSetViewController.h"
#import "DetectView.h"
#import "Detector.h"


@interface TrainDetectorViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;

@property (nonatomic, strong) Detector *detector;
@property (nonatomic, strong) TrainingSet *trainingSet;

@property (weak, nonatomic) IBOutlet DetectView *detectView;
@property (strong, nonatomic) ShowTrainingSetViewController *trainingSetController;


- (IBAction)learnAction:(id)sender;
- (IBAction)addAction:(id)sender;
- (IBAction)numberOfTrainingAction:(id)sender;

@end