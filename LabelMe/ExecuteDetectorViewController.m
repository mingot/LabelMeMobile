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
    float _fpsToShow;
    int _num;
    int _numMax;    
    int _numPyramids;
    double _maxDetectionScore;
    
    //states to show
    BOOL _score;
    BOOL _fps;
    BOOL _scale;
    BOOL _hog;
    
    const NSArray *_detectorColors;
    const NSArray *_settingsStrings;
}

@property (strong, nonatomic) Pyramid *hogPyramid;
@property (strong, nonatomic) NSMutableArray *initialDetectionThresholds; //initial threshold for mutliclass threshold sweeping


@end


@implementation ExecuteDetectorViewController


#pragma mark -
#pragma mark Getters and Setters


- (NSMutableArray *) initialDetectionThresholds
{
    if(!_initialDetectionThresholds){
        _initialDetectionThresholds = [[NSMutableArray alloc] initWithCapacity:self.detectors.count];
        for(Detector *detector in self.detectors)
            [_initialDetectionThresholds addObject:detector.detectionThreshold];
    }
    return _initialDetectionThresholds;
}



#pragma mark -
#pragma mark Initialization and View Lifcycle

- (void) initializeConstants
{
    _detectorColors = [NSArray arrayWithObjects:
                       [UIColor colorWithRed:217/255.0 green:58/255.0 blue:62/255.0 alpha:.6],
                       [UIColor colorWithRed:75/255.0 green:53/255.0 blue:151/255.0 alpha:.6],
                       [UIColor colorWithRed:219/255.0 green:190/255.0 blue:59/255.0 alpha:.6],
                       [UIColor colorWithRed:54/255.0 green:177/255.0 blue:48/255.0 alpha:.6],
                       nil];
    
    _settingsStrings = [[NSArray alloc] initWithObjects:@"Scale",@"FPS",@"Score",@"HOG", nil];
    
    _fpsToShow = 0.0;
    _num = 0;
    _numMax = 1;
    _numPyramids = 15;
    _maxDetectionScore = -0.9;
}


- (BOOL) shouldAutorotate
{
    return NO;
}


- (void)initializeDetectorsWithColors
{
    //assign colors to each detector
    NSMutableDictionary *colorsDictionary = [[NSMutableDictionary alloc] initWithCapacity:self.detectors.count];
    int i=0;
    for(Detector *detector in self.detectors){
        [colorsDictionary setObject:[_detectorColors objectAtIndex:i%_detectorColors.count] forKey:[detector.targetClasses componentsJoinedByString:@"+"]];
        i++;
    }
    self.detectView.colorsDictionary = [NSDictionary dictionaryWithDictionary:colorsDictionary];
}

- (void)initializeSettingsTableView
{
    self.settingsTableView.hidden = YES;
    self.settingsTableView.layer.cornerRadius = 10;
    self.settingsTableView.backgroundColor = [UIColor clearColor];
}

- (void)initializeButtons
{
    [self.cancelButton transformButtonForCamera];    
    [self.settingsButton transformButtonForCamera];
    [self.switchButton transformButtonForCamera];
    self.switchButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.switchButton.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
    [self.switchButton setImage:[UIImage imageNamed:@"switchCamera"] forState:UIControlStateNormal];
}

- (void)initializeSlider
{
    [self.detectionThresholdSliderButton addTarget:self action:@selector(sliderChangeAction:) forControlEvents:UIControlEventValueChanged];
    if(self.detectors.count == 1){
        Detector *detector = [self.detectors objectAtIndex:0];
        self.detectionThresholdSliderButton.value = detector.detectionThreshold.floatValue;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Detector";
    
    [self initializeConstants];
    [self initializeSlider];
    [self initializeDetectorsWithColors];
    [self initializeSettingsTableView];
    [self initializeButtons];
    
    self.infoLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.infoLabel.numberOfLines = 0;
    
    // Add subviews in front of  the prevLayer
    [self.view.layer addSublayer: _prevLayer];
    self.detectView.prevLayer = _prevLayer;
    [self.view addSubview:self.HOGimageView];
    [self.view addSubview:self.detectView];
    
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //set the frame here after all the navigation tabs have been uploaded and we have the definite frame size
    _prevLayer.frame = self.detectView.frame;
    
    //reset the pyramid with the new detectors
    self.hogPyramid = [[Pyramid alloc] initWithDetectors:self.detectors forNumPyramids:_numPyramids];
    
    //Fix Orientation
    [self adaptToPhoneOrientation:[[UIDevice currentDevice] orientation]];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //update detection threshold it it is the only one
    if(self.detectors.count == 1)
        [self.delegate updateDetector:(Detector *)[self.detectors objectAtIndex:0]];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.detectView reset];
}


#pragma mark -
#pragma mark Object Detection

- (NSArray *) detectedBoxesForImage:(UIImage *)image withOrientation:(UIDeviceOrientation *)orientation
{
    NSMutableArray *nmsArray = [[NSMutableArray alloc] init];
    
     //single class detection
    if(self.detectors.count == 1){
        Detector *detector = [self.detectors objectAtIndex:0];
        float detectionThreshold = -1 + 2*detector.detectionThreshold.floatValue;
        [nmsArray addObject:[detector detect:image
                            minimumThreshold:detectionThreshold
                                    pyramids:_numPyramids
                                    usingNms:YES
                           deviceOrientation:orientation
                          learningImageIndex:0]];
    //Multiclass detection
    }else{
        
        [self.hogPyramid constructPyramidForImage:image withOrientation:[[UIDevice currentDevice] orientation]];
        
        //each detector run in parallel
        __block NSArray *candidatesForDetector;
        dispatch_queue_t detectorQueue = dispatch_queue_create("detectorQueue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_apply(self.detectors.count, detectorQueue, ^(size_t i) {
            Detector *detector = [self.detectors objectAtIndex:i];
            float detectionThreshold = -1 + 2*detector.detectionThreshold.floatValue;
            candidatesForDetector = [detector detect:self.hogPyramid minimumThreshold:detectionThreshold usingNms:YES orientation:orientation];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [nmsArray addObject:candidatesForDetector];
            });
        });
        dispatch_release(detectorQueue);
    }
    
    return [NSArray arrayWithArray:nmsArray];
}

- (void)displayOnTheViewTheDetectedBoxes:(NSArray *)detectedBoxes
{
    // set boundaries of the detection and redraw
    self.detectView.cameraOrientation = [[UIDevice currentDevice] orientation];
    //        if([(NSMutableArray *)[nmsArray objectAtIndex:0] count]>0)NSLog(@"boxes:%@", [nmsArray objectAtIndex:0]);
    self.detectView.cornersArray = detectedBoxes;
    [self.detectView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

//override from parent
- (void) processImage:(CGImageRef) imageRef
{
    //start recording FPS
    NSDate * start = [NSDate date];
    
    //construct the image depending on the orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    UIImage *image;
    if(UIDeviceOrientationIsLandscape(orientation)){
        image = [UIImage imageWithCGImage:imageRef];
    }else image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight];
    
    //DETECTION
    NSArray *detectedBoxes = [self detectedBoxesForImage:image withOrientation:orientation];
    
    //DISPLAY BOXES
    [self displayOnTheViewTheDetectedBoxes:detectedBoxes];
    
    // Update the navigation controller title with some information about the detection
    int level = -1;
    float scoreFloat = -1;
    
    //Put the HOG picture on screen
    if (_hog){
        UIImage *image = [ [[UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationRight] scaleImageTo:230/480.0] convertToHogImage];
        [self.HOGimageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
    }
    

    //update label with the current FPS
    _fpsToShow = (_fpsToShow*_num + -1.0/[start timeIntervalSinceNow])/(_num+1);
    _num++;
    NSMutableString *screenLabelText = [[NSMutableString alloc] initWithString:@""];
    if(_score) [screenLabelText appendString:[NSString stringWithFormat:@"score:%.2f\n", scoreFloat]];
    if(_fps) [screenLabelText appendString: [NSString stringWithFormat:@"FPS: %.1f\n",-1.0/[start timeIntervalSinceNow]]];
    if(_scale) [screenLabelText appendString: [NSString stringWithFormat:@"scale: %d\n",level]];
    [self.infoLabel performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithString:screenLabelText] waitUntilDone:YES];
}

#pragma mark -
#pragma mark Settings delegate


-(void) setNumMaximums:(BOOL) value
{
    _numMax = value ? 10 : 1;
}

- (void) setNumPyramidsFromDelegate: (double) value
{
    _numPyramids = (int) value;
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

- (IBAction)switchCameras:(id)sender
{
    [super switchCameras:sender];
}

- (IBAction)showSettingsAction:(id)sender
{
    self.settingsTableView.hidden = self.settingsTableView.hidden? NO:YES;
}

- (IBAction)sliderChangeAction:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    
    //if only one detector executing, update the detection threshold property
    if(self.detectors.count == 1){
        
        Detector *detector = [self.detectors objectAtIndex:0];
        detector.detectionThreshold = [NSNumber numberWithFloat:slider.value];
        
    //if more than one, joinly increase/decrease detection threshold
    }else{
        if(((int)slider.value*100)%4==0){
            for(int i=0; i<self.detectors.count; i++){
                Detector *detector = [self.detectors objectAtIndex:i];
                NSNumber *initialThreshold = [self.initialDetectionThresholds objectAtIndex:i];
                float newThreshold = initialThreshold.floatValue + (slider.value - 0.5);
                newThreshold = newThreshold >= 0 ? newThreshold : 0;
                newThreshold = newThreshold <= 1 ? newThreshold : 1;
                detector.detectionThreshold = [NSNumber numberWithFloat:newThreshold];
            }
        }
        
    }
}


- (IBAction)cancelAction:(id)sender
{
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)switchValueDidChange:(UISwitch *)sw
{
    NSString *label = [_settingsStrings objectAtIndex:sw.tag];
    if([label isEqualToString:@"HOG"]){
        _hog = sw.on;
        if(!_hog) {self.HOGimageView.image = nil; self.HOGimageView.hidden = YES;}
        else self.HOGimageView.hidden = NO;}
    else if([label isEqualToString:@"FPS"]){ _fps = sw.on;}
    else if([label isEqualToString:@"Scale"]){ _scale = sw.on;}
    else if([label isEqualToString:@"Score"]){ _score = sw.on;}
}


#pragma mark -
#pragma mark Table View Data Source and Delegate

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return _settingsStrings.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.opaque = NO;
    
    NSString *label = [_settingsStrings objectAtIndex:indexPath.row];
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
    _prevLayer.orientation = orientation;
    _prevLayer.frame = self.view.frame;
    [CATransaction commit];
}

-(BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:NO];
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}


@end

