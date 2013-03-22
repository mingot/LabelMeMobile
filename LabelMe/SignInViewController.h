//
//  SignInViewController.h
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerConnection.h"
#import "GalleryViewController.h"
#import "SettingsViewController.h"
#import "CreateAccountViewController.h"
#import "CameraOverlayViewController.h"
#import "SendingView.h"

@interface SignInViewController : UIViewController <UITextFieldDelegate,ServerConnectionDelegate,UITabBarControllerDelegate,CreateAccountDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIAlertViewDelegate, SendingViewDelegate>{
    
    UIScrollView   *_scrollView;
    
    UITextField    *_usernameField;
    UITextField    *_passwordField;
    
    UIButton       *_signInButton;
    UIButton       *_forgotPasswordButton;
    UIButton       *_createAccountButton;
    
    
    UIToolbar               *_keyboardToolbar;
    
    UITabBarController      *_tabBarController;
    
    UINavigationController *_navController1;
    UINavigationController *_navController3;
    
    GalleryViewController   *_galleryViewController;
    SettingsViewController   *_settingsViewController;
    SendingView             *sendingView;
    ServerConnection        *sConnection;
   // CameraOverlayViewController *_cameraOverlay;
   // UIImagePickerController *_imagePicker;
    CLLocationManager *locationMng;
    UIPopoverController *_popover;
    BOOL                      keyboardVisible;
    BOOL                      previousSession;

    
    
}
#pragma mark -
#pragma mark Properties
@property (strong,nonatomic) IBOutlet UIScrollView  *scrollView;
@property (strong,nonatomic) IBOutlet UITextField   *usernameField;
@property (strong,nonatomic) IBOutlet UITextField   *passwordField;
@property (strong,nonatomic) IBOutlet UIButton      *signInButton;
@property (strong,nonatomic) IBOutlet UIButton      *forgotPasswordButton;
@property (strong,nonatomic) IBOutlet UIButton      *createAccountButton;
@property (strong,nonatomic) UIToolbar              *keyboardToolbar;
@property (strong,nonatomic) UITabBarController     *tabBarController;
@property (strong,nonatomic) UINavigationController *navController1;
@property (strong,nonatomic) UINavigationController *navController3;
@property (strong,nonatomic) GalleryViewController  *galleryViewController;
@property (strong,nonatomic) SettingsViewController  *settingsViewController;
@property (strong,nonatomic) UIPopoverController     *popover;
//@property (retain,nonatomic) UIImagePickerController *imagePicker;
//@property (retain,nonatomic) CameraOverlayViewController *cameraOverlay;





#pragma mark -
#pragma mark Methods

-(void)keyboardDidShow:(NSNotification *)notif;
-(void)keyboardDidHide:(NSNotification *)notif;
-(IBAction)valueChanged:(id)sender;
-(IBAction)signInAction:(id)sender;
-(IBAction)nextFieldAction:(id)sender;
-(IBAction)previousAction:(id)sender;
-(IBAction)cancelAction:(id)sender;
-(IBAction)createAccountAction:(id)sender;
-(IBAction)forgotPassword:(id)sender;



@end
