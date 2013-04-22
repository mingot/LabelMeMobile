//
//  CameraViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 20/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "CameraViewController.h"
#import <ImageIO/ImageIO.h>

@interface CameraViewController ()

@property int numberImages;
@property BOOL isUsingFrontFacingCamera;

@end




@implementation CameraViewController

@synthesize delegate = _delegate;
@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize numberImagesLabel = _numberImagesLabel;

//private
@synthesize isUsingFrontFacingCamera = _isUsingFrontFacingCamera;



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
    
    self.isUsingFrontFacingCamera = NO;
    self.numberImages = 0;
    self.numberImagesLabel.text = [NSString stringWithFormat:@"%d", self.numberImages];
    
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

    //trick to bring buttons to the front
    UIView *CameraView = [[UIView alloc] init];
	[[self view] addSubview:CameraView];
	[self.view sendSubviewToBack:CameraView];
	[[CameraView layer] addSublayer:self.prevLayer];

}



#pragma mark 
#pragma mark - IBActions


- (IBAction)cancelAction:(id)sender
{
    [self.delegate cancelPhotoCapture];
}

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
        
//		 CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
//		 if (exifAttachments)
//		 
//             // Do something with the attachments.
//             NSLog(@"attachements: %@", exifAttachments);
//		 
//         else NSLog(@"no attachments");
        
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        self.numberImages++;
        [self.numberImagesLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%d",self.numberImages] waitUntilDone:YES];
        [self.delegate addImage:image];
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


@end
