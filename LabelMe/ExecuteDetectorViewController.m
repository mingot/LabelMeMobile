//
//  ExecuteDetectorViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "ExecuteDetectorViewController.h"
#import "ConvolutionHelper.h"
#import "UIImage+HOG.h"
#import "UIImage+Resize.h"



@interface ExecuteDetectorViewController()
{
    float fpsToShow;
    int num;
}

//states to show
@property BOOL score;
@property BOOL fps;
@property BOOL scale;
@property BOOL hog;

@property (strong, nonatomic) NSArray *settingsStrings;

@end



@implementation ExecuteDetectorViewController


@synthesize svmClassifier = _svmClassifier;
@synthesize numPyramids = _numPyramids;
@synthesize maxDetectionScore = _maxDetectionScore;
@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize HOGimageView = _HOGimageView;
@synthesize detectView = _detectView;
@synthesize detectionThresholdSliderButton = _detectionThresholdSliderButton;


//detection
@synthesize trainingSetController = _trainingSetController;
@synthesize imagesList = _imagesList;



#pragma mark -
#pragma mark Getters and Setters


-(NSArray *) settingsStrings
{
    if(!_settingsStrings){
        _settingsStrings = [[NSArray alloc] initWithObjects:@"Scale",@"FPS",@"Score",@"HOG",@"Front", nil];
    }return _settingsStrings;
}

- (BOOL) shouldAutorotate
{
    return NO;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    isUsingFrontFacingCamera = NO;
    fpsToShow = 0.0;
    num = 0;
    self.title = self.svmClassifier.targetClass;
    
    self.settingsTableView.hidden = YES;
    self.settingsTableView.layer.cornerRadius = 10;
    self.settingsTableView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    
    //buttons
    [self.cancelButton transformButtonForCamera];
    [self.settingsButton transformButtonForCamera];
    
    //image poistion detection
    self.trainingSetController = [[ShowTrainingSetViewController alloc] initWithNibName:@"ShowTrainingSetViewController" bundle:nil];
    self.threeDimVC = [[ThreeDimVC alloc] initWithNibName:@"ThreeDimVC" bundle:nil];
    self.imagesList = [[NSMutableArray alloc] init];
    self.rollList = [[NSMutableArray alloc] init];
    self.positionsDic = [[NSMutableDictionary alloc] init];
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];
    self.isRecording = NO;
    
    self.prevLayer = nil;
    
       
    
    //Initialization of model properties
    numMax = 1; 
    self.numPyramids = 15;
    self.maxDetectionScore = -0.9;

    
    // ********  CAMERA CAPUTRE  ********
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
    NSDictionary *videoSettings = [NSDictionary
                                   dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                                   kCVPixelBufferPixelFormatTypeKey,
                                   nil];
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
    
    // Add subviews in front of  the prevLayer
    self.detectView.prevLayer = self.prevLayer;
    [self.view addSubview:self.HOGimageView];
    [self.view addSubview:self.detectView];
    
    //Navigation controller navigation bar
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"settings" style:UIBarButtonItemStyleBordered target:self action:@selector(showSettingsAction:)];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbarBg"]resizableImageWithCapInsets:UIEdgeInsetsZero ] forBarMetrics:UIBarMetricsDefault];
    [settingsButton setStyle:UIBarButtonItemStyleBordered];
    [self.navigationItem setRightBarButtonItem:settingsButton];
    
    //variable number of lines
    self.infoLabel.numberOfLines = 0;
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    //set the frame here after all the navigation tabs have been uploaded and we have the definite frame size
    self.prevLayer.frame = self.detectView.frame;
    
    //Start the capture
    [self.captureSession startRunning];
}

- (BoundingBox *) convertBoundingBoxesForDetectView:(BoundingBox *) cp
{
    BoundingBox *newCP = [[BoundingBox alloc] init];
    double xmin = cp.ymin;
    double ymin = 1 - cp.xmin;
    double xmax = cp.ymax;
    double ymax = 1 - cp.xmax;
    
    CGPoint upperLeft = [self.prevLayer pointForCaptureDevicePointOfInterest:CGPointMake(xmin, ymin)];
    CGPoint lowerRight = [self.prevLayer pointForCaptureDevicePointOfInterest:CGPointMake(xmax, ymax)];
    
    newCP.xmin = upperLeft.x;
    newCP.ymin = upperLeft.y;
    newCP.xmax = lowerRight.x;
    newCP.ymax = lowerRight.y;
    
    return newCP;
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
        //start recording FPS
        NSDate * start = [NSDate date];
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0); //Lock the image buffer ??Why
        
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
        
        double detectionThreshold = -1 + (self.maxDetectionScore + 1)*self.detectionThresholdSliderButton.value;
        NSArray *nmsArray = [self.svmClassifier detect:
                             [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight]
                                      minimumThreshold:detectionThreshold
                                              pyramids:self.numPyramids
                                              usingNms:YES
                                     deviceOrientation:[[UIDevice currentDevice] orientation]
                                    learningImageIndex:0];
        
        
        // set boundaries of the detection and redraw
        [self.detectView setCorners:nmsArray];
        [self.detectView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
        
        // Update the navigation controller title with some information about the detection
        int level=-1;
        float scoreFloat = -1;
        if (nmsArray.count > 0){
            BoundingBox *score = (BoundingBox *)[nmsArray objectAtIndex:0];
            scoreFloat = score.score;
            if(score.score > self.maxDetectionScore) self.maxDetectionScore = score.score;
            if(self.isRecording) [self takePicture:nmsArray for:[UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight]];
            level = score.pyramidLevel;
            
        } 
        
        
        //Put the HOG picture on screen
        if (self.hog){
            UIImage *image = [ [[UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight] scaleImageTo:230/480.0] convertToHogImage];
            [self.HOGimageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
        }
        
        //We unlock the  image buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        CGImageRelease(imageRef);
        
        //update label with the current FPS
        fpsToShow = (fpsToShow*num + -1.0/[start timeIntervalSinceNow])/(num+1);
        num++;
        NSMutableString *screenLabelText = [[NSMutableString alloc] initWithString:@""];
        if(self.score) [screenLabelText appendString:[NSString stringWithFormat:@"score:%.2f\n", scoreFloat]];
        if(self.fps) [screenLabelText appendString: [NSString stringWithFormat:@"FPS: %.1f\n",-1.0/[start timeIntervalSinceNow]]];
        if(self.scale) [screenLabelText appendString: [NSString stringWithFormat:@"scale: %d\n",level]];
        [self.infoLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithString:screenLabelText] waitUntilDone:YES];
        
        
    }
}

#pragma mark -
#pragma mark Settings delegate


-(void) setNumMaximums:(BOOL) value
{
    numMax = value ? 10 : 1;
}

- (void) setNumPyramidsFromDelegate: (double) value
{
    self.numPyramids = (int) value;
}

#pragma mark -
#pragma mark Core Location Delegate

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //    CLLocation *currentLocation = [locations objectAtIndex:0];
    //    NSLog(@"latitude: %f, longitude: %f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude);
}


#pragma mark -
#pragma mark Memory management


-(void)viewDidDisappear:(BOOL)animated{
    [self.captureSession stopRunning];
    [self.detectView reset];
}



#pragma mark -
#pragma mark Position images

- (IBAction)showImagesAction:(id)sender
{
    self.trainingSetController.listOfImages = self.imagesList;
    [self.navigationController pushViewController:self.trainingSetController animated:YES];
}

- (IBAction)showModelAction:(id)sender
{
    //sort images
    //load images in the model
//    self.threeDimVC.imageList = self.imagesList;
    self.threeDimVC.positionsDic = self.positionsDic;
    [self.navigationController pushViewController:self.threeDimVC animated:YES];
    
}

- (IBAction)startRecordingAction:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isRecording = self.isRecording ? NO:YES;
        self.startRecordingButton.titleLabel.text = self.isRecording ? @"start" : @"stop";
        NSLog(self.isRecording ? @"Yes" : @"No");
    });

}

- (void) takePicture:(NSArray *)nmsArray for:(UIImage *)image
{
    BoundingBox *bb = [nmsArray objectAtIndex:0];
    CMAttitude *attitude = self.motionManager.deviceMotion.attitude;
    NSLog(@"pitch: %f, yaw:%f, roll:%f", attitude.pitch, attitude.yaw, attitude.roll);
    

    NSString *key = [NSString stringWithFormat:@"%d/%d",(int)round(attitude.pitch*10), (int)round(attitude.roll*10)];
    if(self.positionsDic.count == 0 || [self.positionsDic objectForKey:key]==nil){
        [self.positionsDic setObject:[image croppedImage:[bb rectangleForImage:image]] forKey:key];
        NSLog(@"Added key %@ and total: %d", key, self.positionsDic.count);
    }
}


#pragma mark -
#pragma mark IBActions

-(IBAction)showSettingsAction:(id)sender
{
    self.settingsTableView.hidden = self.settingsTableView.hidden? NO:YES;
}




- (IBAction)cancelAction:(id)sender
{
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)switchCameras:(id)sender

{
    AVCaptureDevicePosition desiredPosition = isUsingFrontFacingCamera ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;

    
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
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

- (IBAction)switchValueDidChange:(UISwitch *)sw
{
    
    NSString *label = [self.settingsStrings objectAtIndex:sw.tag];
    if([label isEqualToString:@"HOG"]){
        self.hog = sw.on;
        if(!self.hog) {self.HOGimageView.image = nil; self.HOGimageView.hidden = YES;}
        else self.HOGimageView.hidden = NO;
    }else if([label isEqualToString:@"FPS"]){ self.fps = sw.on;
    }else if([label isEqualToString:@"Scale"]){ self.scale = sw.on;
    }else if([label isEqualToString:@"Score"]){ self.score = sw.on;
    }else if([label isEqualToString:@"Front"]){
        [self switchCameras:self];
    }
}


#pragma mark -
#pragma mark Table View Data Source and Delegate

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{

    return self.settingsStrings.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    [sw setOnTintColor:[UIColor colorWithRed:(180.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0]];
    
    NSString *label = [self.settingsStrings objectAtIndex:indexPath.row];
    cell.textLabel.text = label;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    [sw setOn:NO  animated:NO];
    sw.tag = indexPath.row;
    [sw addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    
    return cell;
}



@end

