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
@property (strong, nonatomic) NSMutableArray *initialDetectionThresholds; //initial threshold for mutliclass threshold sweeping
@property (strong, nonatomic) NSArray *colors; //static array of colors to assign to multiple detectors


@end



@implementation ExecuteDetectorViewController


@synthesize svmClassifiers = _svmClassifiers;
@synthesize numPyramids = _numPyramids;
@synthesize maxDetectionScore = _maxDetectionScore;
@synthesize captureSession = _captureSession;
@synthesize prevLayer = _prevLayer;
@synthesize HOGimageView = _HOGimageView;
@synthesize detectView = _detectView;
@synthesize detectionThresholdSliderButton = _detectionThresholdSliderButton;




#pragma mark -
#pragma mark Getters and Setters


-(NSArray *) settingsStrings
{
    if(!_settingsStrings){
        _settingsStrings = [[NSArray alloc] initWithObjects:@"Scale",@"FPS",@"Score",@"HOG", nil];
    }return _settingsStrings;
}

- (NSMutableArray *) initialDetectionThresholds
{
    if(!_initialDetectionThresholds){
        _initialDetectionThresholds = [[NSMutableArray alloc] initWithCapacity:self.svmClassifiers.count];
        for(Classifier *svmClassifier in self.svmClassifiers)
            [_initialDetectionThresholds addObject:svmClassifier.detectionThreshold];
    }
    return _initialDetectionThresholds;
}

- (NSArray *) colors
{
    if(!_colors) _colors = [NSArray arrayWithObjects:
                            [UIColor colorWithRed:217/255.0 green:58/255.0 blue:62/255.0 alpha:.6],
                            [UIColor colorWithRed:75/255.0 green:53/255.0 blue:151/255.0 alpha:.6],
                            [UIColor colorWithRed:219/255.0 green:190/255.0 blue:59/255.0 alpha:.6],
                            [UIColor colorWithRed:54/255.0 green:177/255.0 blue:48/255.0 alpha:.6],
                            nil];
    return _colors;
}

#pragma mark -
#pragma mark View Lifcycle


- (BOOL) shouldAutorotate
{
    return NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.infoLabel.numberOfLines = 0;
    
    
    isUsingFrontFacingCamera = NO;
    fpsToShow = 0.0;
    num = 0;
    self.title = @"Detector";
    
    //slider
    [self.detectionThresholdSliderButton addTarget:self action:@selector(sliderChangeAction:) forControlEvents:UIControlEventValueChanged];
    if(self.svmClassifiers.count == 1){
        Classifier *classifier = [self.svmClassifiers objectAtIndex:0];        
        self.detectionThresholdSliderButton.value = classifier.detectionThreshold.floatValue;
    }
    
    //assign colors to each detector
    NSMutableDictionary *colorsDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.svmClassifiers.count];
    int i=0;
    for(Classifier *classifier in self.svmClassifiers){
        [colorsDictionary setObject:[self.colors objectAtIndex:i%self.colors.count] forKey:[classifier.targetClasses componentsJoinedByString:@"+"]];
        i++;
    }
    self.detectView.colorsDictionary = [NSDictionary dictionaryWithDictionary:colorsDictionary];
    
    self.settingsTableView.hidden = YES;
    self.settingsTableView.layer.cornerRadius = 10;
    self.settingsTableView.backgroundColor = [UIColor clearColor];
    
    //buttons
    [self.cancelButton transformButtonForCamera];    
    [self.settingsButton transformButtonForCamera];
    [self.switchButton transformButtonForCamera];
    self.switchButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.switchButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    [self.switchButton setImage:[UIImage imageNamed:@"switchCamera"] forState:UIControlStateNormal];
    
    
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
	self.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	self.captureOutput.alwaysDiscardsLateVideoFrames = YES;
	
    // Output queue setting (for receiving captures from AVCaptureSession delegate)
	dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
	[self.captureOutput setSampleBufferDelegate:self queue:queue];
	dispatch_release(queue);
    
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSDictionary *videoSettings = [NSDictionary
                                   dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
                                   kCVPixelBufferPixelFormatTypeKey,
                                   nil];
	[self.captureOutput setVideoSettings:videoSettings];
    
    
    //Capture session definition
	self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:captureInput];
	[self.captureSession addOutput:self.captureOutput];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    // Previous layer to show the video image
	self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
	self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	[self.view.layer addSublayer: self.prevLayer];
    
    // Add subviews in front of  the prevLayer
    self.detectView.prevLayer = self.prevLayer;
    [self.view addSubview:self.HOGimageView];
    [self.view addSubview:self.detectView];
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    //set the frame here after all the navigation tabs have been uploaded and we have the definite frame size
    self.prevLayer.frame = self.detectView.frame;
    
    //reset the pyramid with the new detectors
    self.hogPyramid = [[Pyramid alloc] initWithClassifiers:self.svmClassifiers forNumPyramids:self.numPyramids];
    
    //Start the capture
    [self.captureSession startRunning];
    
    //Fix Orientation
    [self adaptToPhoneOrientation:[[UIDevice currentDevice] orientation]];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //update detection threshold it it is the only one
    if(self.svmClassifiers.count == 1)
        [self.delegate updateClassifier:(Classifier *)[self.svmClassifiers objectAtIndex:0]];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [self.captureSession stopRunning];
    [self.detectView reset];
}

- (void)viewDidUnload
{
    [self setSwitchButton:nil];
    [self setImageView:nil];
    [super viewDidUnload];
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

        //**** DETECTION ****
        NSMutableArray *nmsArray = [[NSMutableArray alloc] init];

        //rotate image depending on the orientation
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        UIImage *image;
        if(UIDeviceOrientationIsLandscape(orientation)){
            image = [UIImage imageWithCGImage:imageRef];
        }else image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight];

        
        if(self.takePicture){
            [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
            self.takePicture = NO;
        }
        
        
        //single class detection
        if(self.svmClassifiers.count == 1){
            Classifier *svmClassifier = [self.svmClassifiers objectAtIndex:0];
            float detectionThreshold = -1 + 2*svmClassifier.detectionThreshold.floatValue;
            [nmsArray addObject:[svmClassifier detect:image
                                      minimumThreshold:detectionThreshold
                                              pyramids:self.numPyramids
                                              usingNms:YES
                                     deviceOrientation:orientation
                                    learningImageIndex:0]];
        //Multiclass detection
        }else{
            
            [self.hogPyramid constructPyramidForImage:image withOrientation:[[UIDevice currentDevice] orientation]];
            
            //each classifier run in parallel
            __block NSArray *candidatesForClassifier;
            dispatch_queue_t classifierQueue = dispatch_queue_create("classifierQueue", DISPATCH_QUEUE_CONCURRENT);
            dispatch_apply(self.svmClassifiers.count, classifierQueue, ^(size_t i) {
                Classifier *svmClassifier = [self.svmClassifiers objectAtIndex:i];
                float detectionThreshold = -1 + 2*svmClassifier.detectionThreshold.floatValue;
                candidatesForClassifier = [svmClassifier detect:self.hogPyramid minimumThreshold:detectionThreshold usingNms:YES orientation:orientation];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [nmsArray addObject:candidatesForClassifier];
                });
            });
            dispatch_release(classifierQueue);
        }
        //**** END DETECTION ****
        
        
        // set boundaries of the detection and redraw
        self.detectView.cameraOrientation = [[UIDevice currentDevice] orientation];
//        if([(NSMutableArray *)[nmsArray objectAtIndex:0] count]>0)NSLog(@"boxes:%@", [nmsArray objectAtIndex:0]);
        self.detectView.cornersArray = nmsArray;
        [self.detectView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
        
        // Update the navigation controller title with some information about the detection
        int level = -1;
        float scoreFloat = -1;        
        
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
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            self.infoLabel.text = screenLabelText;
//        });

    }
}


//- (void) writeOnImage:(UIImage *)image
//{
////    //correct the orientation diference between UIImage and the underlying CGImage to make them coincide
////    UIImage *correctedImage = [self fixOrientation];
//    
//    // Inizialization
//    CGImageRef imageRef = image.CGImage;
//    
//    // Get the image in bits: Create a context and draw the image there to get the image in bits
//    NSUInteger width = CGImageGetWidth(imageRef); //#pixels width
//    NSUInteger height = CGImageGetHeight(imageRef); //#pixels height
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    int bytesPerPixel = 4;
//    int bytesPerRow = bytesPerPixel * width;
//    int bitsPerComponent = 8;
//    UInt8 *im = (UInt8 *)malloc(height * width * 4);
//    
//    CGContextRef contextImage = CGBitmapContextCreate(im, width, height,
//                                                      bitsPerComponent, bytesPerRow, colorSpace,
//                                                      kCGImageAlphaPremultipliedLast| kCGBitmapByteOrder32Big );
//    CGColorSpaceRelease(colorSpace);
//    CGContextDrawImage(contextImage, CGRectMake(0, 0, width, height), imageRef);
//    CGContextRelease(contextImage);
//    
//    for(int j=0;j<height;j++)
//        for(int i=0;i<width;i++)
//            NSLog(@"component (%d,%d): R=%d, G=%d, B=%d, A=%d",i,j,im[4*j*width + i*4],im[4*j*width + i*4 + 1],im[4*j*width + i*4 + 2],im[4*j*width + i*4 + 3]);
//    
//    NSLog(@"Fin");
//    
//    //create an image from the current graphics context
//    UIGraphicsBeginImageContext(myView.bounds.size);
//    [myView.layer renderInContext:UIGraphicsGetCurrentContext()];
//    viewImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//}

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
#pragma mark IBActions

-(IBAction)showSettingsAction:(id)sender
{
    self.settingsTableView.hidden = self.settingsTableView.hidden? NO:YES;
}

- (IBAction)sliderChangeAction:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    
    //if only one classifier executing, update the detection threshold property
    if(self.svmClassifiers.count == 1){
        
        Classifier *classifier = [self.svmClassifiers objectAtIndex:0];
        classifier.detectionThreshold = [NSNumber numberWithFloat:slider.value];
        
    //if more than one, joinly increase/decrease detection threshold
    }else{
        if(((int)slider.value*100)%4==0){
            for(int i=0; i<self.svmClassifiers.count; i++){
                Classifier *svmClassifier = [self.svmClassifiers objectAtIndex:i];
                NSNumber *initialThreshold = [self.initialDetectionThresholds objectAtIndex:i];
                float newThreshold = initialThreshold.floatValue + (slider.value - 0.5);
                newThreshold = newThreshold >= 0 ? newThreshold : 0;
                newThreshold = newThreshold <= 1 ? newThreshold : 1;
                svmClassifier.detectionThreshold = [NSNumber numberWithFloat:newThreshold];
            }
        }
        
    }
}


- (IBAction)cancelAction:(id)sender
{
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController popViewControllerAnimated:NO];
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
    self.detectView.frontCamera = isUsingFrontFacingCamera;
}

- (IBAction)switchValueDidChange:(UISwitch *)sw
{
    
    NSString *label = [self.settingsStrings objectAtIndex:sw.tag];
    if([label isEqualToString:@"HOG"]){
        self.hog = sw.on;
        if(!self.hog) {self.HOGimageView.image = nil; self.HOGimageView.hidden = YES;}
        else self.HOGimageView.hidden = NO;}
    else if([label isEqualToString:@"FPS"]){ self.fps = sw.on;}
    else if([label isEqualToString:@"Scale"]){ self.scale = sw.on;}
    else if([label isEqualToString:@"Score"]){ self.score = sw.on;}
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

    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.opaque = NO;
    
    NSString *label = [self.settingsStrings objectAtIndex:indexPath.row];
    cell.textLabel.text = label;

    //switch
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    [sw setOnTintColor:[UIColor colorWithRed:(180.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0]];
    [sw setOn:NO  animated:NO];
    sw.tag = indexPath.row;
    [sw addTarget:self action:@selector(switchValueDidChange:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    
    return cell;
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

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:NO];
    
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}



- (IBAction)takePictureAction:(id)sender
{
    self.takePicture = YES;
}
@end

