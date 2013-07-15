//
//  CameraViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 20/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "CameraViewController.h"
#import "UIImage+Resize.h"
#import "UIImage+Rotation.h"


@interface CameraViewController ()

@property BOOL isUsingFrontFacingCamera;

@end



@implementation CameraViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isUsingFrontFacingCamera = NO;
    
    [self.switchButton transformButtonForCamera];
    self.switchButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.switchButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    [self.switchButton setImage:[UIImage imageNamed:@"switchCamera"] forState:UIControlStateNormal];
    [self.cancelButton transformButtonForCamera];
    [self.captureButton transformButtonForCamera];
    CGRect captButton = self.captureButton.frame;
    self.captureButton.frame = CGRectMake(captButton.origin.x, captButton.origin.y, captButton.size.width, captButton.size.height*1.2);
    [self.captureButton setTitle:@"" forState:UIControlStateNormal];
    [self.captureButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
    
    self.thumbnailCaptureImageView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.thumbnailCaptureImageView.layer.borderWidth = 1;
        
    // ********  CAMERA CAPTURE  ********
    //Capture input specifications
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
                                          error:nil];

    //still image capture
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    //Capture session definition
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:self.stillImageOutput]; //still image output
    [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // Previous layer to show the video image
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    //trick to put de capture previous layer at the back
    [self.view addSubview:self.cameraView];
    [self.view sendSubviewToBack:self.cameraView];
    [self.cameraView.layer addSublayer:self.prevLayer];
}

-(void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    self.thumbnailCaptureImageView.image = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Previous layer to show the video image
        self.prevLayer.frame = self.view.frame;
        [self.captureSession startRunning];
    });
    
    //fix orientation
    [self adaptToPhoneOrientation:[[UIDevice currentDevice] orientation]];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [self.captureSession stopRunning];
    [super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark IBActions


- (IBAction)captureAction:(id)sender
{
    //animation
    [UIView animateWithDuration:0.2f
                     animations:^{
                         [self.cameraView setAlpha:0.5f];
                     }
                     completion:^(BOOL finished){
                         [self.cameraView setAlpha:1];
                     }
     ];
    
    //orientation
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in self.stillImageOutput.connections){
		for (AVCaptureInputPort *port in [connection inputPorts])
			if ([[port mediaType] isEqual:AVMediaTypeVideo] ){
				videoConnection = connection;
                [videoConnection setVideoOrientation:[UIDevice currentDevice].orientation];
				break;
			}
		if (videoConnection) break; 
	}
	
    //image taken
	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        self.thumbnailCaptureImageView.image = image;
        [self.delegate addImageCaptured:image];
	 }];
}


- (IBAction)toggleFrontAction:(id)sender

{
    AVCaptureDevicePosition desiredPosition = self.isUsingFrontFacingCamera ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[self.prevLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[self.prevLayer session] inputs])
                [[self.prevLayer session] removeInput:oldInput];
            
            [[self.prevLayer session] addInput:input];
            [[self.prevLayer session] commitConfiguration];
            break;
        }
    }
    self.isUsingFrontFacingCamera = !self.isUsingFrontFacingCamera;
}

- (IBAction)cancelAction:(id)sender
{
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark -
#pragma mark Rotation

- (void)willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self adaptToPhoneOrientation:toInterfaceOrientation];
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) adaptToPhoneOrientation:(UIDeviceOrientation) orientation
{
    [CATransaction begin];
    self.prevLayer.orientation = orientation;
    self.prevLayer.frame = self.view.frame;
    [CATransaction commit];
}

@end
