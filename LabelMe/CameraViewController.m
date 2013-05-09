//
//  CameraViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 20/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <ImageIO/ImageIO.h>
#import "CameraViewController.h"
#import "DDExpandableButton.h"


@interface CameraViewController ()

@property int numberImages;
@property BOOL isUsingFrontFacingCamera;

-(AYUIButton *) setCameraButton: (AYUIButton *)button;

@end



@implementation CameraViewController

@synthesize delegate = _delegate;
@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;

//private
@synthesize isUsingFrontFacingCamera = _isUsingFrontFacingCamera;
@synthesize numberImages = _numberImages;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isUsingFrontFacingCamera = NO;
    self.numberImages = 0;
    
    self.captureButton = [self setCameraButton:self.captureButton];
    [self.captureButton setTitle:@"" forState:UIControlStateNormal];
    [self.captureButton setImage:[UIImage imageNamed:@"camera.png"] forState:UIControlStateNormal];
    self.switchButton = [self setCameraButton:self.switchButton];
    self.cancelButton = [self setCameraButton:self.cancelButton];
    
    
    self.thumbnailCaptureImageView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.thumbnailCaptureImageView.layer.borderWidth = 1;
    self.thumbnailCaptureImageView.hidden = YES;

    //switch cameras button
    UIBarButtonItem *switchCameraButton = [[UIBarButtonItem alloc] initWithTitle:@"switch" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleFrontAction:)];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbarBg"]resizableImageWithCapInsets:UIEdgeInsetsZero ] forBarMetrics:UIBarMetricsDefault];
    [switchCameraButton setStyle:UIBarButtonItemStyleBordered];
    [self.navigationItem setRightBarButtonItem:switchCameraButton];
    

    
    // ********  CAMERA CAPTURE  ********
    //Capture input specifications
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
                                          deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
                                          error:nil];
    
    //Capture output specifications
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    
    // Output queue setting (for receiving captures from AVCaptureSession delegate)
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,nil];
    [captureOutput setVideoSettings:videoSettings];

    //still image capture
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    //Capture session definition
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:captureInput];
    [self.captureSession addOutput:captureOutput]; //video output
    [self.captureSession addOutput:self.stillImageOutput]; //still image output
    [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // Previous layer to show the video image
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.prevLayer.frame = self.view.frame;
    [self.captureSession startRunning];

    //trick to put de capture previous layer at the back
    UIView *cameraView = [[UIView alloc] init];
    [self.view addSubview:cameraView];
	[self.view sendSubviewToBack:cameraView];
	[cameraView.layer addSublayer:self.prevLayer];
}

-(void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

#pragma mark -
#pragma mark IBActions


- (IBAction)captureAction:(id)sender
{
    
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in self.stillImageOutput.connections){
		for (AVCaptureInputPort *port in [connection inputPorts])
			if ([[port mediaType] isEqual:AVMediaTypeVideo] ){
				videoConnection = connection;
				break;
			}
		if (videoConnection) break; 
	}
	
	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        
        
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        self.thumbnailCaptureImageView.image = image;
        self.numberImages++;
        [self.delegate addImageCaptured:image];
        self.thumbnailCaptureImageView.hidden = NO;
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
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Private methods


-(AYUIButton *) setCameraButton: (AYUIButton *)button;
{
    button.layer.cornerRadius = 10;
    button.layer.borderColor = [[UIColor blackColor] CGColor];
    button.layer.borderWidth = 1;
    [button setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.4]];
    [button setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.8] forState:UIControlStateHighlighted];
    [button setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.4] forState:UIControlStateNormal];
    [button setTitleColor:[self.captureButton titleColorForState:UIControlStateNormal] forState:UIControlStateHighlighted];
    return button;
}

@end
