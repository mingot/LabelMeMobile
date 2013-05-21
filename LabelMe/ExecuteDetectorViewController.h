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
#import "AYUIButton.h"
#import "Pyramid.h"


@protocol ExecuteDetectorViewControllerDelegate <NSObject>

@optional //just for updating detectionthreshold when a single classifier is called
- (void) updateClassifier:(Classifier *) classifier;

@end


@interface ExecuteDetectorViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    //settings
    int numMax;
    BOOL isUsingFrontFacingCamera;
}

@property (nonatomic, strong) id<ExecuteDetectorViewControllerDelegate> delegate;

//model properties
@property (nonatomic,strong) NSArray *svmClassifiers;
@property int numPyramids;
@property double maxDetectionScore;
@property (nonatomic, strong) Pyramid *hogPyramid;

//AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;

//self views
@property (nonatomic, weak) IBOutlet UIImageView *HOGimageView;
@property (nonatomic, weak) IBOutlet DetectView *detectView;
@property (weak, nonatomic) IBOutlet UISlider *detectionThresholdSliderButton;
@property (weak, nonatomic) IBOutlet AYUIButton *settingsButton;
@property (weak, nonatomic) IBOutlet AYUIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;


//info label
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

//settings view
@property (weak, nonatomic) IBOutlet UIView *settingsView;
- (IBAction)showSettingsAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)switchCameras:(id)sender;
- (IBAction)switchValueDidChange:(UISwitch *)sw;

@end