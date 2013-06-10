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
#import "AYUIButton.h"

@protocol CameraViewControllerDeledate <NSObject>

- (void) addImageCaptured:(UIImage *)image;

@end



@interface CameraViewController : UIViewController 


@property (strong, nonatomic) id<CameraViewControllerDeledate> delegate;

//AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

//xib
@property (weak, nonatomic) IBOutlet AYUIButton *captureButton;
@property (weak, nonatomic) IBOutlet AYUIButton *switchButton;
@property (weak, nonatomic) IBOutlet AYUIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailCaptureImageView;
@property (weak, nonatomic) IBOutlet UIView *cameraView;

- (IBAction)captureAction:(id)sender;
- (IBAction)toggleFrontAction:(id)sender;
- (IBAction)cancelAction:(id)sender;


@end
