//
//  SignInViewController.m
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "SignInViewController.h"
#import "NSObject+ShowAlert.h"
#import "NSObject+Folders.h"
#import "NSString+checkValidity.h"
#import "ServerConnection.h"
#import "GalleryViewController.h"
#import "Constants.h"
#import "UIImage+Resize.h"
#import "Reachability.h"

@interface SignInViewController ()

@end

@implementation SignInViewController

@synthesize scrollView = _scrollView;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize signInButton = _signInButton;
@synthesize forgotPasswordButton = _forgotPasswordButton;
@synthesize createAccountButton = _createAccountButton;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize tabBarController = _tabBarController;
@synthesize galleryViewController = _galleryViewController;
@synthesize settingsViewController = _settingsViewController;
//@synthesize cameraOverlay = _cameraOverlay;
//@synthesize imagePicker = _imagePicker;
@synthesize navController1 = _navController1;
@synthesize navController3 = _navController3;
@synthesize popover = _popover;


#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self createRememberMeFolder];
        locationMng = [[CLLocationManager alloc] init];
        locationMng.desiredAccuracy = kCLLocationAccuracyKilometer;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
   
    self.keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    [self.keyboardToolbar setBarStyle:UIBarStyleBlackOpaque];
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextFieldAction:)];
    UIBarButtonItem *previousButton = [[UIBarButtonItem alloc]initWithTitle:@"Previous" style:UIBarButtonItemStyleBordered target:self action:@selector(previousAction:)];
    previousButton.enabled = NO;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(signInAction:)];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    doneButton.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.keyboardToolbar setItems:[NSArray arrayWithObjects:previousButton,nextButton,flexibleSpace,cancelButton, doneButton,nil]];
    [self.usernameField setInputAccessoryView:self.keyboardToolbar];
    [self.usernameField setDelegate:self];
    [self.usernameField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [self.passwordField setInputAccessoryView:self.keyboardToolbar];
    [self.passwordField setDelegate:self];
    [self.passwordField setSecureTextEntry:YES];
    [self.passwordField setKeyboardAppearance:UIKeyboardAppearanceAlert];
    sConnection = [[ServerConnection alloc] init];
    sConnection.delegate = self;

    [self.scrollView setContentSize:self.view.frame.size];
    previousSession = [self rememberMe];
    sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    [sendingView setDelegate:self];
    [sendingView.label setNumberOfLines:1];
    [sendingView setHidden:YES];
    [sendingView.progressView setHidden:YES];
    [sendingView.label setText:@"Signing in..."];
    [self.view addSubview:sendingView];
    
   
}

#pragma mark -
#pragma mark Views Appear

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    // Register keyboard events
    [self.usernameField setText:@""];
    [self.passwordField setText:@""];
    previousSession = [self rememberMe];
   /* if (previousSession) {
        [self signInAction:nil];
    }*/
   
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    keyboardVisible = NO;
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (previousSession) {
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        if  (networkStatus == NotReachable) {
            [self signInWithoutConnection];
        }
        else{
            [self signInAction:nil];
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    // Unregister keyboard events
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.view.frame.size.height);
    keyboardVisible = NO;
}
#pragma mark -
#pragma mark Keyboard Events
-(void)keyboardDidShow:(NSNotification *)notif{
    if (keyboardVisible) {
		return;
	}
	
	// The keyboard wasn't visible before
	
	// Get the origin of the keyboard when it finishes animating
	NSDictionary *info = [notif userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	// Get the top of the keyboard in view's coordinate system.
	// We need to set the bottom of the scrollview to line up with it
	CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
	CGFloat keyboardTop = keyboardRect.origin.y;
    
	// Resize the scroll view to make room for the keyboard
    CGRect viewFrame = self.view.bounds;
	viewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
	
	self.scrollView.frame = viewFrame;
	keyboardVisible = YES;
    [self.scrollView scrollRectToVisible:self.passwordField.frame animated:YES];

    
    
    
}
-(void)keyboardDidHide:(NSNotification *)notif{
    
    if (!keyboardVisible) {
        return;
    }
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.view.frame.size.height);
    keyboardVisible = NO;
}
#pragma mark -
#pragma mark IBActions 
-(IBAction)signInAction:(id)sender{
    
    //[self.signInButton setEnabled:NO];
    [self cancelAction:nil];
    [sendingView setHidden:NO];
    [sendingView.activityIndicator startAnimating];

    [sConnection checkLoginForUsername:self.usernameField.text andPassword:self.passwordField.text];
    

    
}
-(IBAction)nextFieldAction:(id)sender{
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    UIBarButtonItem * nextButton =[[self.keyboardToolbar items] objectAtIndex:1];
    nextButton.enabled = NO;
    previousButton.enabled = YES;
    [self.passwordField becomeFirstResponder];
}
-(IBAction)previousAction:(id)sender{
    UIBarButtonItem * nextButton = [[self.keyboardToolbar items] objectAtIndex:1];
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    nextButton.enabled = YES;
    previousButton.enabled = NO;
    [self.usernameField becomeFirstResponder];
    
}
-(IBAction)cancelAction:(id)sender{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];

}
-(IBAction)createAccountAction:(id)sender{
    CreateAccountViewController *createAccountViewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
       
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        
        if (screenSize.size.height == 568) {
            createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPhone5" bundle:nil];
            
            
        }
        else if (screenSize.size.height == 480){
            createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPhone" bundle:nil];
            
            
        }
    }
    else{
        createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPad" bundle:nil];

    }
    createAccountViewController.delegate = self;

    //[createAccountViewController setModalTransitionStyle:UIModalTransitionStylePartialCurl];
    [self presentViewController:createAccountViewController animated:YES completion:NULL ];
    //[self.navigationController pushViewController:createAccountViewController animated:YES];


}
-(IBAction)forgotPassword:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Please, enter your email address." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}
-(IBAction)valueChanged:(id)sender{
    UIBarButtonItem * doneButton = [[self.keyboardToolbar items] objectAtIndex:4];
    
    if ((self.passwordField.text.length*self.usernameField.text.length)==0) {
        [doneButton setEnabled:NO];
    }
    else{
        [doneButton setEnabled:YES];
    }
    
}

#pragma mark -
#pragma mark Previous Session Methods

-(void)createRememberMeFolder{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error;
    BOOL isDir = YES;
    if (![filemng fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] isDirectory:&isDir]) {
        if([filemng createDirectoryAtPath:[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] withIntermediateDirectories:YES attributes:nil error:&error]){
        }
    }
}

-(BOOL)saveSessionWithUsername:(NSString *) username andPassword:(NSString *) password{
    NSError *error;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if([username writeToFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"] atomically:NO encoding:NSUTF8StringEncoding error:&error]){
        if ([password writeToFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"] atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            return YES;
        }
    }
    return NO;
}
-(BOOL)rememberMe{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error;
    BOOL isDir = NO;
    
    if ([filemng fileExistsAtPath:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"]  isDirectory:&isDir]) {
        self.usernameField.text = [NSString stringWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"]  encoding:NSUTF8StringEncoding error:&error];
            NSArray *paths = [self newArrayWithFolders:self.usernameField.text];
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
        NSNumber *signinnum = [dict objectForKey:@"signinauto"];
        if (signinnum.boolValue) {
            if ([filemng fileExistsAtPath:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"]  isDirectory:&isDir]) {
                self.passwordField.text = [NSString stringWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"]  encoding:NSUTF8StringEncoding error:&error];
                return YES;
            }

        else{
            self.passwordField.text = @"";
        }
        }

        //[paths release];
    }
    return NO;
}
#pragma mark -
#pragma mark UIAlertView Delegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        ServerConnection *sconnecton = [[ServerConnection alloc]init];
        if ([[alertView textFieldAtIndex:0].text checkEmailFormat] ) {
            [sconnecton forgotPassword:[alertView textFieldAtIndex:0].text];
            [self errorWithTitle:@"Forgot Password" andDescription:@"An email will be sent to you with your username and a new password."];
        }
        else{
            [self errorWithTitle:@"Email format is not valid" andDescription:@"Enter a valid email."];
        }
        
    }
    
    
}

#pragma mark -
#pragma mark Text Field Delegate Methods
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    
    if (textField == self.passwordField) {
        [self nextFieldAction:nil];
    }
    else if (textField == self.usernameField){
        [self previousAction:nil];
    }
    
    [self.scrollView scrollRectToVisible:textField.frame animated:YES];
}
#pragma mark -
#pragma mark CreateAccountDelegate Methods
-(void)signIn{
    previousSession = [self rememberMe];
    
    
}
#pragma mark -
#pragma mark ServerConnectionDelegate Methods
-(void)cancel{
    [sConnection cancelRequestFor:0];
    [sendingView setHidden:YES];
    [sendingView.activityIndicator stopAnimating];

}
#pragma mark -
#pragma mark ServerConnectionDelegate Methods


-(void)signInComplete{
    if (!previousSession) {
        [self saveSessionWithUsername:self.usernameField.text andPassword:self.passwordField.text];
                
    }
    [self createUserFolders:self.usernameField.text];
    //[self.signInButton setEnabled:YES];
    self.tabBarController =[[UITabBarController alloc]init];
    self.tabBarController.delegate = self;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        
        if (screenSize.size.height == 568) {
             self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPhone5" bundle:nil];
            self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone5" bundle:nil];

            
                    }
        else if (screenSize.size.height == 480){
             self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPhone" bundle:nil];
            self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone" bundle:nil];

            
    
            }
        
        
        
    }
    else{
        self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPad" bundle:nil];
        self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPad" bundle:nil];


    }
   
    [self.galleryViewController setUsername:self.usernameField.text];
    UIViewController *viewcontroller = [[UIViewController alloc]init];
    viewcontroller.tabBarItem =[[UITabBarItem alloc]initWithTitle:@"Camera" image:nil tag:1];
    [viewcontroller.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"camera.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"cameraActive.png"]];
    self.navController1 = [[UINavigationController alloc] initWithRootViewController:self.galleryViewController];
    self.navController3 = [[UINavigationController alloc] initWithRootViewController:self.settingsViewController];
    [self.settingsViewController setUsername:self.usernameField.text];

    
    self.tabBarController.viewControllers = @[self.navController1,viewcontroller,self.navController3];
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.usernameField.text] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    if (![filemng fileExistsAtPath:path]) {
        [sConnection downloadProfilePictureToUsername:self.usernameField.text];
    }
    
    
  
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"previousTab"]) {
        case 0:
            [self.tabBarController setSelectedViewController:self.navController1];
            break;
        case 2:
            [self.tabBarController setSelectedViewController:self.navController3];
            break;
            
        default:
            break;
            
            
    }
    [sendingView setHidden:YES];
    [sendingView.activityIndicator stopAnimating];
    [self presentViewController:self.tabBarController animated:YES completion:NULL];


    


    //ir a la galeria del usuario
}
-(void)profilePictureReceived:(UIImage *)ppicture{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.usernameField.text] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    if ([filemng createFileAtPath:path contents:UIImageJPEGRepresentation([ppicture thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil]) {
        [self.settingsViewController.tableView reloadData];
        [self.galleryViewController.profilePicture setImage:ppicture];
    }
}
-(void)signInWithoutConnection{
    //[self.signInButton setEnabled:YES];
  
    if (previousSession) {
        [self signInComplete];
        //ir a la galeria del usuario

    }
    else{
        [self errorWithTitle:@"No internet connection" andDescription:@"The app could not connect."];
        [sendingView setHidden:YES];
        [sendingView.activityIndicator stopAnimating];


    }
}
-(void)signInError{
    //[self.signInButton setEnabled:YES];
    [sendingView setHidden:YES];


}
#pragma mark -
#pragma mark TabBarController Delegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
    if (tabBarController.selectedIndex == 1) {
        //[[tabBarController tabBar] setHidden:YES];

        //[self.cameraOverlay.tagViewController setUsername:self.usernameField.text];
        //[tabBarController presentViewController:self.cameraOverlay.imagePicker animated:NO completion:NULL];
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        [imagePicker setDelegate:self];
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
            
        }
        else{
            [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {

        //[tabBarController presentViewController:imagePicker animated:NO completion:NULL];
          [tabBarController.selectedViewController presentViewController:imagePicker animated:NO completion:NULL];

        }
        else{
            if ([imagePicker sourceType] == UIImagePickerControllerSourceTypePhotoLibrary ) {
                if ([self.popover isPopoverVisible]) {
                    [self.popover dismissPopoverAnimated:YES];
                    
                }
                else{
                    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
                    [popover presentPopoverFromBarButtonItem:[tabBarController.tabBar.items objectAtIndex:1] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES ];
                    
                    self.popover = popover;
                }

            }
            else{
                [tabBarController.selectedViewController presentViewController:imagePicker animated:NO completion:NULL];

                
            }
            
        }
        
        switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"previousTab"]) {
            case 0:
                [tabBarController setSelectedViewController:[[tabBarController viewControllers]objectAtIndex:0]];
                break;
            case 2:
                [tabBarController setSelectedViewController:[[tabBarController viewControllers]objectAtIndex:2]];
                break;
                
            default:
                break;
                
                
        }
        

    }
    else{
        //previousViewController = [tabBarController selectedIndex];
        [[NSUserDefaults standardUserDefaults] setInteger:[tabBarController selectedIndex] forKey:@"previousTab"];




    }
}
#pragma mark -
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    //[picker.cameraOverlayView addSubview:sendingView];
    //[sendingView setHidden:NO];

    [locationMng startUpdatingLocation];
    
    TagViewController *tagviewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];
        
        if (screenSize.size.height == 568) {
            tagviewController = [[TagViewController alloc] initWithNibName:@"TagViewController_iPhone5" bundle:nil];
            
            
        }
        else if (screenSize.size.height == 480){
            tagviewController = [[TagViewController alloc] initWithNibName:@"TagViewController_iPhone" bundle:nil];

            
        }
        
        
        
    }
    else{
        tagviewController = [[TagViewController alloc] initWithNibName:@"TagViewController_iPad" bundle:nil];

    }
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        
                
   
    [tagviewController setUsername:self.usernameField.text];
    
    NSArray *paths = [self newArrayWithFolders:self.usernameField.text];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *camerarollnum = [dict objectForKey:@"cameraroll"];
    NSNumber *resolutionnum = [dict objectForKey:@"resolution"];
    CGSize newSize = image.size;
    if ((camerarollnum.boolValue)&& (picker.sourceType == UIImagePickerControllerSourceTypeCamera )) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    float max;
    if (newSize.width>newSize.height) {
        max = newSize.width;
    }
    else{
            max = newSize.height;
    }
    if ((resolutionnum.floatValue != 0.0) && (resolutionnum.floatValue < max)) {
        if (image.size.height > image.size.width) {
            newSize = CGSizeMake(resolutionnum.floatValue*0.75, resolutionnum.floatValue);
        }
        else{
            newSize = CGSizeMake(resolutionnum.floatValue, resolutionnum.floatValue*0.75);
            
        }
    }
        
        
        
    
    
    
    [tagviewController performSelectorInBackground:@selector(saveImage:) withObject:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];
   /* dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        [tagviewController saveImage:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];
    });*/

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    NSString *location = [[NSString alloc] initWithString:@""];
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        location = [[locationMng.location.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
    }
    [location writeToFile:[[paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[[tagviewController.filename stringByDeletingPathExtension] stringByAppendingString:@".txt"]] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
   
    [picker setNavigationBarHidden:NO animated:NO];
    [tagviewController setImage:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];

    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
        [self.popover dismissPopoverAnimated:NO];
        [tagviewController setHidesBottomBarWhenPushed:YES];
        [self.galleryViewController.navigationController pushViewController:tagviewController animated:YES];
        
    }
    else{
        [picker pushViewController:tagviewController animated:YES];

        
    }

    [locationMng stopUpdatingLocation];
    
    
    
    

}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
        [self.popover dismissPopoverAnimated:YES];

    }
    else{
        [picker dismissViewControllerAnimated:YES completion:NULL];

    }
}
#pragma mark -
#pragma mark Presenting TagviewController
-(void)presentTagviewControllerWithImage:(UIImage *)image{
    
}

#pragma mark -
#pragma mark Restoration

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    
    self.scrollView;
    self.usernameField;
    self.passwordField;
    self.keyboardToolbar;
    self.signInButton;
    self.forgotPasswordButton;
    self.createAccountButton;
    self.tabBarController;
    self.navController1;
    self.navController3;
    self.galleryViewController;
    self.settingsViewController;
    
}
@end
