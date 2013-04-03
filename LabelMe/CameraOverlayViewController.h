//
//  CameraOverlayViewController.h
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "TagViewController.h"

@interface CameraOverlayViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIBarButtonItem *cameraRollButton;
    UIButton *lastPhotoButton;
    CLLocationManager *locationMng;
}

@property (nonatomic,strong) UIImagePickerController *imagePicker;
@property (nonatomic,strong) TagViewController *tagViewController;
@property (nonatomic,strong) IBOutlet UIButton *flashButton;
@property (nonatomic,strong) IBOutlet UIButton *autoButton;
@property (nonatomic,strong) IBOutlet UIButton *onButton;
@property (nonatomic,strong) IBOutlet UIButton *offButton;
@property (nonatomic,strong) IBOutlet UIButton *cameraButton;


-(IBAction)cameraRollAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)takePhotoAction:(id)sender;
-(IBAction)flashAction:(id)sender;
-(IBAction)autoAction:(id)sender;
-(IBAction)onAction:(id)sender;
-(IBAction)offAction:(id)sender;
-(IBAction)cameraAction:(id)sender;


@end
