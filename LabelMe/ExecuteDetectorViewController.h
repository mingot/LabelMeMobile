//
//  ExecuteDetectorViewController.h
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
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>


#import "DetectView.h"
#import "SettingsViewController.h"
#import "Classifier.h"
#import "ShowTrainingSetViewController.h"
#import "ThreeDimVC.h"


@interface ExecuteDetectorViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate>
{
    //settings
    BOOL hogOnScreen;
    int numMax;
    BOOL isUsingFrontFacingCamera;
}


//position detection
@property (nonatomic, strong) ShowTrainingSetViewController *trainingSetController;
@property (nonatomic, strong) ThreeDimVC *threeDimVC;
@property (nonatomic, strong) NSMutableArray *imagesList;
@property (nonatomic, strong) NSMutableArray *rollList;
@property (nonatomic, strong) NSMutableDictionary *positionsDic;
@property (weak, nonatomic) IBOutlet UIButton *showImagesButton;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property BOOL isRecording;
- (IBAction)showImagesAction:(id)sender;
- (IBAction)showModelAction:(id)sender;
- (IBAction)startRecordingAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *startRecordingButton;


//model properties
@property (nonatomic,strong) Classifier *svmClassifier;
@property int numPyramids;
@property double maxDetectionScore;

//Core Location
@property (nonatomic, strong) CLLocationManager *locMgr;

//AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;

//self views
@property (nonatomic, weak) IBOutlet UIImageView *HOGimageView;
@property (nonatomic, weak) IBOutlet DetectView *detectView;

@property (weak, nonatomic) IBOutlet UISlider *detectionThresholdSliderButton;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *scaleLabel;

- (IBAction)switchCameras:(id)sender;

@end