//
//  CameraViewController.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 20/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>

@protocol CameraViewControllerDeledate <NSObject>

- (void) cancelPhotoCapture;
- (void) addImageCaptured:(UIImage *)image;

@end



@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>


@property (strong, nonatomic) id<CameraViewControllerDeledate> delegate;

//AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

//xib
@property (weak, nonatomic) IBOutlet UILabel *numberImagesLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
- (IBAction)captureAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)toggleFrontAction:(id)sender;


@end
