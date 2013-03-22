//
//  CameraOverlayViewController.m
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "CameraOverlayViewController.h"
#import "NSObject+Folders.h"
#import "Constants.h"
#import "UIImage+Resize.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>

@interface CameraOverlayViewController ()

@end

@implementation CameraOverlayViewController
@synthesize imagePicker = _imagePicker;
@synthesize tagViewController = _tagViewController;
@synthesize flashButton = _flashButton;
@synthesize autoButton = _autoButton;
@synthesize onButton = _onButton;
@synthesize offButton = _offButton;
@synthesize cameraButton = _cameraButton;
//@synthesize imageToAnnotate = _imageToAnnotate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        lastPhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)
                           ];
        [lastPhotoButton addTarget:self action:@selector(cameraRollAction:) forControlEvents:UIControlEventTouchUpInside];
        [lastPhotoButton setBackgroundColor:[UIColor grayColor]];
        lastPhotoButton.layer.masksToBounds = YES;
        lastPhotoButton.layer.cornerRadius = 5.0;
        locationMng = [[CLLocationManager alloc] init];
        locationMng.desiredAccuracy = kCLLocationAccuracyKilometer;
        //self.imageToAnnotate = [[UIImage alloc] init];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            CGRect screenSize = [[UIScreen mainScreen] bounds];
            
            if (screenSize.size.height == 568) {
                
                self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone5" bundle:nil];

            }
            else if (screenSize.size.height == 480){
                
                self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPhone" bundle:nil];

            }
            
            
            
        }
        else{
            self.tagViewController = [[TagViewController alloc]initWithNibName:@"TagViewController_iPad" bundle:nil];

        }
        self.imagePicker = [[UIImagePickerController alloc] init];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.imagePicker.showsCameraControls = NO;
            
            
            if ([[self.imagePicker.cameraOverlayView subviews] count] == 0)
            {
                
                // setup our custom overlay view for the camera
                //
                // ensure that our custom view's frame fits within the parent frame
                CGRect overlayViewFrame = self.imagePicker.cameraOverlayView.frame;
                CGRect newFrame = CGRectMake(0.0,
                                             CGRectGetHeight(overlayViewFrame) -
                                             self.view.frame.size.height - 10.0,
                                             CGRectGetWidth(overlayViewFrame),
                                             self.view.frame.size.height + 10.0);
                self.view.frame = newFrame;
                overlayViewFrame.size.height = overlayViewFrame.size.height - newFrame.size.height;
                [self.imagePicker.view addSubview:self.view];
                [self.flashButton setFrame:CGRectMake(20, 20, self.flashButton.frame.size.width, self.flashButton.frame.size.height)];
                [self.autoButton setFrame:CGRectMake(20, 20+self.flashButton.frame.size.height, self.autoButton.frame.size.width, self.autoButton.frame.size.height)];
                [self.onButton setFrame:CGRectMake(20, self.autoButton.frame.origin.y+self.autoButton.frame.size.height, self.onButton.frame.size.width, self.onButton.frame.size.height)];
                [self.offButton setFrame:CGRectMake(20, self.onButton.frame.origin.y+self.onButton.frame.size.height, self.offButton.frame.size.width, self.offButton.frame.size.height)];
                [self.cameraButton setFrame:CGRectMake(self.view.frame.size.width - self.cameraButton.frame.size.width- 20, 20, self.cameraButton.frame.size.width, self.cameraButton.frame.size.height)];
                
                [self.autoButton setHidden:YES];
                [self.onButton setHidden:YES];
                [self.offButton setHidden:YES];
                
                
                [self.imagePicker.cameraOverlayView addSubview:self.flashButton];
                [self.imagePicker.cameraOverlayView addSubview:self.autoButton];
                [self.imagePicker.cameraOverlayView addSubview:self.onButton];
                [self.imagePicker.cameraOverlayView addSubview:self.offButton];
                [self.imagePicker.cameraOverlayView addSubview:self.cameraButton];
                if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ) {
                    [self.cameraButton setHidden:YES];
                    
                }
                if (![UIImagePickerController isFlashAvailableForCameraDevice:[self.imagePicker cameraDevice]] ) {
                    [self.flashButton setHidden:NO];
                    
                }
            
            }
            


        }
        else{
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

        }
        self.imagePicker.delegate = self;
            }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"] ;
    //barImage = [barImage resizedImage:CGSizeMake(barImage.size.width, barImage.size.height/2) interpolationQuality:kCGInterpolationHigh];
    [cameraRollButton setCustomView:lastPhotoButton];

    [self.imagePicker.navigationBar setBackgroundImage:barImage forBarMetrics:UIBarMetricsDefault];

    [self.imagePicker.navigationBar setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];

   	// Do any additional setup after loading the view.
}
-(void) lastPhoto{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                 usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                     if (nil != group) {
                                         // be sure to filter the group so you only get photos
                                         [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                                         
                                         
                                         [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1]
                                                                 options:0
                                                              usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                                                  if (nil != result) {
                                                                      ALAssetRepresentation *repr = [result defaultRepresentation];
                                                                      // this is the most recent saved photo
                                                                      UIImage *img = [[UIImage alloc] initWithCGImage:[repr fullScreenImage]];
                                                                      [lastPhotoButton setImage:[img thumbnailImage:100 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh] forState:UIControlStateNormal];
                                                                      // we only need the first (most recent) photo -- stop the enumeration
                                                                      img = nil;
                                                                      *stop = YES;
                                                                  }
                                                              }];
                                     }
                                     
                                     *stop = NO;
                                 } failureBlock:^(NSError *error) {
                                 }];
    
    
}
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (viewController == self.tagViewController) {
        //[self.tagViewController setImage:self.imageToAnnotate];
        [self.tagViewController setImage:self.tagViewController.imageView.image];
        //[self.tagViewController performSelectorInBackground:@selector(saveImage) withObject:nil];
    
        //[self.tagViewController saveImage];
        //[self setImageToAnnotate:nil];
    }
    else {
        //[self.view setHidden:NO];
        
    }

    
}
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{

    if (viewController == self.tagViewController) {
        [self.view setHidden:YES];

        
    }
    else if([viewController.class.description isEqualToString:@"PLUICameraViewController"]){
        [self.view setHidden:NO];
        [self lastPhoto];

        
    }

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.imagePicker.sourceType != UIImagePickerControllerSourceTypeCamera) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {

            [self.imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [self.view setHidden:NO];
        }

    }
    [self.imagePicker.cameraOverlayView setHidden:YES];
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(showButtons:)
                                   userInfo:self.imagePicker.cameraOverlayView
                                    repeats:YES];
   }
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.imagePicker.cameraOverlayView setHidden:YES];


    
}
- (void)showButtons:(NSTimer*)theTimer {
    UIView *cameraOverlayView = (UIView *)theTimer.userInfo;
    UIView *previewView = cameraOverlayView.superview.superview;
    
    if (previewView != nil) {
        [cameraOverlayView removeFromSuperview];
        [previewView insertSubview:cameraOverlayView atIndex:1];
        
        cameraOverlayView.hidden = NO;
        
        [theTimer invalidate];
    }
}
-(IBAction)cameraRollAction:(id)sender{
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.view setHidden:YES];
    CGRect viewFrame = [[UIScreen mainScreen] bounds];
    viewFrame.origin.y+=20;
    viewFrame.size.height-=20;
    [self.imagePicker.view setFrame:viewFrame];
 
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}
-(IBAction)cancelAction:(id)sender{
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

    [self.imagePicker dismissViewControllerAnimated:YES completion:NULL];
}
-(IBAction)takePhotoAction:(id)sender{
    [locationMng startUpdatingLocation];

    [self.imagePicker takePicture];
}
-(IBAction)flashAction:(id)sender{
    switch (self.imagePicker.cameraFlashMode) {
        case UIImagePickerControllerCameraFlashModeOff:
            [self.autoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.onButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.offButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            break;
        case UIImagePickerControllerCameraFlashModeAuto:
            [self.autoButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [self.onButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.offButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
        case UIImagePickerControllerCameraFlashModeOn:
            [self.autoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.onButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            [self.offButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    [self.autoButton setHidden:!self.autoButton.hidden];
    [self.onButton setHidden:!self.onButton.hidden];
    [self.offButton setHidden:!self.offButton.hidden];
    
}
-(IBAction)autoAction:(id)sender{
    [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeAuto];
    [self.autoButton setHidden:YES];
    [self.onButton setHidden:YES];
    [self.offButton setHidden:YES];
}
-(IBAction)onAction:(id)sender{
    [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOn];
    [self.autoButton setHidden:YES];
    [self.onButton setHidden:YES];
    [self.offButton setHidden:YES];
    
}
-(IBAction)offAction:(id)sender{
    [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
    [self.autoButton setHidden:YES];
    [self.onButton setHidden:YES];
    [self.offButton setHidden:YES];
}
-(IBAction)cameraAction:(id)sender{
    switch (self.imagePicker.cameraDevice) {
        case UIImagePickerControllerCameraDeviceRear:
            [self.imagePicker setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            break;
        case UIImagePickerControllerCameraDeviceFront:
            [self.imagePicker setCameraDevice:UIImagePickerControllerCameraDeviceRear];
            break;
            
        default:
            break;
    }
   
    if (![UIImagePickerController isFlashAvailableForCameraDevice:[self.imagePicker cameraDevice]] ) {
        [self.flashButton setHidden:YES];
        
    }
    else{
        [self.flashButton setHidden:NO];
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if (self.imagePicker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {

        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self.view setHidden:NO];
        [self.imagePicker.view setFrame:[[UIScreen mainScreen] bounds]];
        [self.imagePicker.cameraOverlayView setHidden:YES];
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(showButtons:)
                                       userInfo:self.imagePicker.cameraOverlayView
                                        repeats:YES];
            return;
        }
    

    }
        [self.imagePicker dismissViewControllerAnimated:YES completion:NULL];
    
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    //[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
   // [self.imagePicker dismissViewControllerAnimated:YES completion:nil];
    //[self.tagViewController setGallery:NO];
    [self.tagViewController.annotationView reset];
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    [self.tagViewController setImage:image];
    [self.tagViewController performSelectorInBackground:@selector(saveImage) withObject:nil];
 
    NSArray *paths = [self newArrayWithFolders:self.tagViewController.username];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *camerarollnum = [dict objectForKey:@"cameraroll"];
    NSNumber *resolutionnum = [dict objectForKey:@"resolution"];
    CGSize newSize = image.size;
    if  (self.imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera ) {
        if (camerarollnum.boolValue) {
             UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
        if (image.size.height > image.size.width) {
                newSize = CGSizeMake(resolutionnum.floatValue*0.75, resolutionnum.floatValue);
        }
        else{
                newSize = CGSizeMake(resolutionnum.floatValue, resolutionnum.floatValue*0.75);
                
        }



    }
    else{
        if (image.size.height > image.size.width) {
            if (image.size.height > resolutionnum.floatValue) {
                newSize = CGSizeMake(resolutionnum.floatValue*image.size.width/image.size.height, resolutionnum.floatValue);
            }
            
        }
        else{
            if (image.size.width > resolutionnum.floatValue) {
                newSize = CGSizeMake(resolutionnum.floatValue, resolutionnum.floatValue*image.size.height/image.size.width);
            }

            
        }
        
    }

    //[self.imagePicker presentModalViewController:self.tagViewController animated:YES];
    //[self setImageToAnnotate:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

    
    //[self.imagePicker.navigationController pushViewController:self.tagViewController animated:NO];
    

    NSString *location = [[NSString alloc] initWithString:@""];

    if (self.imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        location = [[locationMng.location.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
    }
    [location writeToFile:[[paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[[self.tagViewController.filename stringByDeletingPathExtension] stringByAppendingString:@".txt"]] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    if (self.imagePicker.sourceType != UIImagePickerControllerSourceTypeCamera) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {

            [self.imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [self.view setHidden:NO];
            [self.imagePicker.view setFrame:[[UIScreen mainScreen] bounds]];
        }
    }
    [self.imagePicker setNavigationBarHidden:NO animated:NO];
    [self.imagePicker pushViewController:self.tagViewController animated:NO];
    [locationMng stopUpdatingLocation];
    


   // [paths release];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    self.imagePicker;
    self.tagViewController;
    //[self.imageToAnnotate release];
}
@end
