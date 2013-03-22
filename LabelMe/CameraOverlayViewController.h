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

@interface CameraOverlayViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    UIImagePickerController *_imagePicker;
    TagViewController *_tagViewController;
    IBOutlet UIBarButtonItem *cameraRollButton;
    UIButton *lastPhotoButton;
    UIButton *_flashButton;
    UIButton *_autoButton;
    UIButton *_onButton;
    UIButton *_offButton;
    UIButton *_cameraButton;
    CLLocationManager *locationMng;
   // UIImage *_imageToAnnotate;

}
@property (nonatomic,retain) UIImagePickerController *imagePicker;
@property (nonatomic,retain) TagViewController *tagViewController;
//@property (nonatomic,retain) UIImage *imageToAnnotate;
@property (nonatomic,retain) IBOutlet UIButton *flashButton;
@property (nonatomic,retain) IBOutlet UIButton *autoButton;
@property (nonatomic,retain) IBOutlet UIButton *onButton;
@property (nonatomic,retain) IBOutlet UIButton *offButton;
@property (nonatomic,retain) IBOutlet UIButton *cameraButton;


-(IBAction)cameraRollAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)takePhotoAction:(id)sender;
-(IBAction)flashAction:(id)sender;
-(IBAction)autoAction:(id)sender;
-(IBAction)onAction:(id)sender;
-(IBAction)offAction:(id)sender;
-(IBAction)cameraAction:(id)sender;


@end
