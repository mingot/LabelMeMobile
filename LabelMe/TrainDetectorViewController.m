//
//  TrainDetectorViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "TrainDetectorViewController.h"
#include <stdlib.h> // For random number generation using arc4random

#import "UIImage+Resize.h"
#import "ConvolutionHelper.h"




@interface TrainDetectorViewController ()
{
    // change state when learnAction button is pressed
    bool takePhoto; 
}


//defined outside the viewDidLoad to change easily it's title
@property UIBarButtonItem *numberOfTrainingButton; 

@end




@implementation TrainDetectorViewController

@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize detectView = _detectView;
@synthesize trainingSet = _trainingSet;
@synthesize numberOfTrainingButton = _numberOfTrainingButton;
@synthesize trainingSetController = _trainingSetController;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.trainingSetController = [[ShowTrainingSetViewController alloc] initWithNibName:@"ShowTrainingSetViewController" bundle:nil];
    
    takePhoto = NO;
    
    //TODO: current fixed maximum capacity for the number of example images
    self.trainingSet = [[TrainingSet alloc] init];
    self.svmClassifier = [[Classifier alloc] init];
    
    // NavigatinoBar buttons and labels
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
    UIBarButtonItem *learnButton = [[UIBarButtonItem alloc] initWithTitle:@"Learn" style:UIBarButtonItemStyleBordered target:self action:@selector(learnAction:)];
    self.numberOfTrainingButton = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%d",self.trainingSet.images.count] style:UIBarButtonItemStyleBordered target:self action:@selector(numberOfTrainingAction:)];
    self.navigationItem.rightBarButtonItems = [[NSArray alloc] initWithObjects: learnButton, addButton, self.numberOfTrainingButton, nil];
    
    
    // ********  CAMERA CAPUTRE  ********
    //Capture input specifications
    AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:nil];
    
    //Capture output specifications
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	captureOutput.alwaysDiscardsLateVideoFrames = YES;
	
    // Output queue setting (for receiving captures from AVCaptureSession delegate)
	dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
	[captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
	[captureOutput setVideoSettings:videoSettings];
    
    //Capture session definition
	self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:captureOutput];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    // Previous layer to show the video image
	self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
	self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.prevLayer];
    
    //detectView setting
    self.detectView.prevLayer = self.prevLayer;
    [self.view addSubview:self.detectView];
}


- (void) viewDidAppear:(BOOL)animated
{
    //set the frame here after all the navigation tabs have been uploaded and we have the definite frame size
    self.prevLayer.frame = self.detectView.frame;
    
    //Insert the detect Frame in the view
    BoundingBox *detectFrame = [[BoundingBox alloc] initWithRect:CGRectMake(3.0/8, 3.0/8, 1.0/4, 1.0/4) label:0 imageIndex:0];
    [self.detectView setCorners:[[NSArray alloc] initWithObjects:detectFrame, nil]];
    [self.detectView setNeedsDisplay];
    
    //Reset the number of training images in the button
    [self.numberOfTrainingButton setTitle:[NSString stringWithFormat:@"%d",self.trainingSet.images.count]];
    
    //Start the capture
    [self.captureSession startRunning];
}


- (void)viewDidUnload
{
    [self setDetectView:nil];
    [super viewDidUnload];
}


- (void) printRectangle: (CGRect) rect
{
    NSLog(@"H:%f W:%f origin.x:%f origin.y:%f", rect.size.height, rect.size.width, rect.origin.x, rect.origin.y);
}


#pragma mark 
#pragma mark AVCaptureSession delegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0); //Lock the image buffer
        
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
        
        if(takePhoto) //Asynch for when the addButton (addAction) is pressed
        {
            // Make the UIImage and change the orientation
            UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight];
            
            [self.trainingSet.images addObject:image];
            
            // add ground truth bounding box
            BoundingBox *boundingBox = [[BoundingBox alloc] initWithRect:CGRectMake(3.0/8, 3.0/8, 1.0/4, 1.0/4) label:1 imageIndex:[self.trainingSet.images count]-1];
            [self.trainingSet.groundTruthBoundingBoxes addObject:boundingBox];
            
            // update the number of training images on the button title
            [self.numberOfTrainingButton performSelectorOnMainThread:@selector(setTitle:) withObject:[NSString stringWithFormat:@"%d",[self.trainingSet.images count]] waitUntilDone:YES];
            
            takePhoto = NO;
        }
        
        //We unlock the  image buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        CGImageRelease(imageRef);
        
    }
}

#pragma mark
#pragma mark Actions

- (IBAction)learnAction:(id)sender
{
    // Modal for choosing a name
    [self.svmClassifier train:self.trainingSet];
    
    NSLog(@"learn went great");
    
    // write the template to a file
//    [self.svmClassifier storeSvmWeightsAsTemplateWithName:@"prova5.txt"];
    
    //Learn creating a new queue
    
}

- (IBAction)addAction:(id)sender
{
    takePhoto = YES;
}


- (IBAction)numberOfTrainingAction:(id)sender
{
    //Perform segue to table view of learning images
    [self.trainingSet initialFill];
    NSMutableArray *listOfImages = [[NSMutableArray alloc] initWithCapacity:[self.trainingSet.boundingBoxes count]];
    
    for(int i=0; i< self.trainingSet.boundingBoxes.count; i++)
    {
        BoundingBox *cp = [self.trainingSet.boundingBoxes objectAtIndex:i];
        UIImage *wholeImage = [self.trainingSet.images objectAtIndex:cp.imageIndex];
        CGSize templateSize;
        templateSize.height = 72;
        templateSize.width = 54;
        UIImage *croppedImage = [wholeImage croppedImage:[cp rectangleForImage:wholeImage]];
        [listOfImages addObject:[croppedImage resizedImage:templateSize interpolationQuality:kCGInterpolationDefault]];
    }
    
    
    self.trainingSetController.listOfImages = listOfImages;
//    self.trainingSetController.listOfImages = self.trainingSet.images;
    
    [self.navigationController pushViewController:self.trainingSetController animated:YES];
}

@end