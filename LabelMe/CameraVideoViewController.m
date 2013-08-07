//
//  CameraVideoViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 07/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "CameraVideoViewController.h"

@interface CameraVideoViewController ()
{
    @private
      BOOL _isUsingFrontCamera;
      AVCaptureSession *_captureSession;
      AVCaptureVideoDataOutput *_captureOutput;
    
    @protected
      AVCaptureVideoPreviewLayer *_prevLayer;
}


@end

@implementation CameraVideoViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // ********  CAMERA CAPUTRE  ********
    //Capture input specifications
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]
										  error:nil];
    
    //Capture output specifications
	_captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	_captureOutput.alwaysDiscardsLateVideoFrames = YES;
	
    // Output queue setting (for receiving captures from AVCaptureSession delegate)
	dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
	[_captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSDictionary *videoSettings = [NSDictionary
                                   dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                                   kCVPixelBufferPixelFormatTypeKey,
                                   nil];
	[_captureOutput setVideoSettings:videoSettings];
    
    
    //Capture session definition
	_captureSession = [[AVCaptureSession alloc] init];
	[_captureSession addInput:captureInput];
	[_captureSession addOutput:_captureOutput];
    [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    // Previous layer to show the video image
	_prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
	_prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: _prevLayer];
    
    // Add subviews in front of  the prevLayer
//    self.detectView.prevLayer = self.prevLayer;
    
}

- (void) viewDidAppear:(BOOL)animated
{
    //set the frame here after all the navigation tabs have been uploaded and we have the definite frame size
//    self.prevLayer.frame = self.detectView.frame;
    
    //Start the capture
    [_captureSession startRunning];
    
}


-(void)viewDidDisappear:(BOOL)animated
{
    [_captureSession stopRunning];
}


#pragma mark -
#pragma mark Public methods

- (IBAction)switchCameras:(id)sender
{
    AVCaptureDevicePosition desiredPosition = _isUsingFrontCamera ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [[_prevLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[_prevLayer session] inputs])
                [[_prevLayer session] removeInput:oldInput];
            
            [[_prevLayer session] addInput:input];
            [[_prevLayer session] commitConfiguration];
            break;
        }
    }
    _isUsingFrontCamera = !_isUsingFrontCamera;
}

#pragma mark -
#pragma mark AVCaptureSession delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
    
	//We create an autorelease pool because as we are not in the main_queue our code is not executed in the main thread.
    @autoreleasepool
    {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        //Get information about the image
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        //Create a CGImageRef from the CVImageBufferRef
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef imageRef = CGBitmapContextCreateImage(newContext);
        
        //We release some components
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        [self processImage:image];
        
    }
}

#pragma mark -
#pragma mark Private methods

- (void) processImage:(UIImage *) image;
{
    
}


@end
