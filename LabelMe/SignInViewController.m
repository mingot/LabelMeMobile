//
//  SignInViewController.m
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "SignInViewController.h"
#import "Constants.h"
#import "Reachability.h"

#import "UIImage+Resize.h"
#import "NSObject+ShowAlert.h"
#import "NSObject+Folders.h"
#import "NSString+checkValidity.h"




@implementation SignInViewController

@synthesize scrollView = _scrollView;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize signInButton = _signInButton;
@synthesize forgotPasswordButton = _forgotPasswordButton;
@synthesize createAccountButton = _createAccountButton;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize tabBarController = _tabBarController;
@synthesize popover = _popover;
@synthesize galleryViewController = _galleryViewController;
@synthesize settingsViewController = _settingsViewController;
@synthesize detectorGalleryController = _detectorGalleryController;
@synthesize userDictionary = _userDictionary;
@synthesize userPaths = _userPaths;




#pragma mark 
#pragma mark - lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self createRememberMeFolder];
        
        //GPS settings
        locationMng = [[CLLocationManager alloc] init];
        locationMng.desiredAccuracy = kCLLocationAccuracyKilometer;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    //buttons settings
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(nextFieldAction:)];
    UIBarButtonItem *previousButton = [[UIBarButtonItem alloc]initWithTitle:@"Previous" style:UIBarButtonItemStyleBordered target:self action:@selector(previousAction:)];
    previousButton.enabled = NO;
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(signInAction:)];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    doneButton.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    self.keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.keyboardToolbar.barStyle = UIBarStyleBlackOpaque;
    self.keyboardToolbar.items = [NSArray arrayWithObjects:previousButton,nextButton,flexibleSpace,cancelButton, doneButton,nil];
    
    self.usernameField.inputAccessoryView = self.keyboardToolbar;
    self.usernameField.delegate = self;
    self.usernameField.keyboardAppearance = UIKeyboardAppearanceAlert;
    
    self.passwordField.inputAccessoryView = self.keyboardToolbar;
    self.passwordField.delegate = self;
    self.passwordField.secureTextEntry = YES;
    self.passwordField.keyboardAppearance = UIKeyboardAppearanceAlert;
    
    sConnection = [[ServerConnection alloc] init];
    sConnection.delegate = self;

    self.scrollView.contentSize = self.view.frame.size;
    
    previousSession = [self rememberMe];
    
    sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    sendingView.delegate = self;
    sendingView.label.numberOfLines = 1;
    sendingView.hidden = YES;
    sendingView.progressView.hidden = YES;
    sendingView.label.text = @"Signing in...";
    
    [self.view addSubview:sendingView];
    


}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    // Register keyboard events
    [self.usernameField setText:@""];
    [self.passwordField setText:@""];
    previousSession = [self rememberMe];   
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    keyboardVisible = NO;    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (previousSession) {
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        
        if(networkStatus == NotReachable) [self signInWithoutConnection];
        else [self signInAction:nil];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    // Unregister keyboard events
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.view.frame.size.height);
    keyboardVisible = NO;
}


#pragma mark -
#pragma mark Keyboard Events

-(void)keyboardDidShow:(NSNotification *)notif
{
    if (keyboardVisible)
		return;
	
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


-(void)keyboardDidHide:(NSNotification *)notif
{
    if (!keyboardVisible) {
        return;
    }
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.view.frame.size.height);
    keyboardVisible = NO;
}


#pragma mark -
#pragma mark IBActions 

-(IBAction)signInAction:(id)sender
{

    [self cancelAction:nil];
    [sendingView setHidden:NO];
    [sendingView.activityIndicator startAnimating];

    [sConnection checkLoginForUsername:self.usernameField.text andPassword:self.passwordField.text];
}


-(IBAction)nextFieldAction:(id)sender
{
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    UIBarButtonItem * nextButton =[[self.keyboardToolbar items] objectAtIndex:1];
    nextButton.enabled = NO;
    previousButton.enabled = YES;
    [self.passwordField becomeFirstResponder];
}

-(IBAction)previousAction:(id)sender
{
    UIBarButtonItem * nextButton = [[self.keyboardToolbar items] objectAtIndex:1];
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    nextButton.enabled = YES;
    previousButton.enabled = NO;
    [self.usernameField becomeFirstResponder];
    
}

-(IBAction)cancelAction:(id)sender
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];

}
-(IBAction)createAccountAction:(id)sender
{
    CreateAccountViewController *createAccountViewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([UIScreen mainScreen].bounds.size.height == 568)
            createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPhone5" bundle:nil];
        else if ([UIScreen mainScreen].bounds.size.height == 480)
            createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPhone" bundle:nil];
    }else createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPad" bundle:nil];

    createAccountViewController.delegate = self;

    [self presentViewController:createAccountViewController animated:YES completion:NULL ];
}


-(IBAction)forgotPassword:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Please, enter your email address." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}

-(IBAction)valueChanged:(id)sender
{
    UIBarButtonItem * doneButton = [[self.keyboardToolbar items] objectAtIndex:4];
    
    if ((self.passwordField.text.length*self.usernameField.text.length)==0)
        [doneButton setEnabled:NO];
    
    else [doneButton setEnabled:YES];
    
}


#pragma mark -
#pragma mark Previous Session Methods

-(void)createRememberMeFolder
{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error;
    BOOL isDir = YES;
    if (![filemng fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] isDirectory:&isDir]) {
        if([filemng createDirectoryAtPath:[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] withIntermediateDirectories:YES attributes:nil error:&error]){
        }
    }
}

-(BOOL)saveSessionWithUsername:(NSString *) username andPassword:(NSString *) password
{
    NSError *error;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if([username writeToFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"] atomically:NO encoding:NSUTF8StringEncoding error:&error]){
        if ([password writeToFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"] atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)rememberMe
{
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
                
            }else self.passwordField.text = @"";
        }

    }
    return NO;
}



#pragma mark -
#pragma mark UIAlertView Delegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        ServerConnection *sconnecton = [[ServerConnection alloc]init];
        if ([[alertView textFieldAtIndex:0].text checkEmailFormat] ) {
            [sconnecton forgotPassword:[alertView textFieldAtIndex:0].text];
            [self errorWithTitle:@"Forgot Password" andDescription:@"An email will be sent to you with your username and a new password."];
            
        } else [self errorWithTitle:@"Email format is not valid" andDescription:@"Enter a valid email."];
    }
}


#pragma mark -
#pragma mark Text Field Delegate Methods

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.passwordField)
        [self nextFieldAction:nil];
    else if (textField == self.usernameField)
        [self previousAction:nil];
    
    [self.scrollView scrollRectToVisible:textField.frame animated:YES];
}


#pragma mark -
#pragma mark CreateAccountDelegate Methods
-(void)signIn
{
    previousSession = [self rememberMe];
}


#pragma mark -
#pragma mark ServerConnectionDelegate Methods

-(void)cancel
{
    [sConnection cancelRequestFor:0];
    [sendingView setHidden:YES];
    [sendingView.activityIndicator stopAnimating];
}


#pragma mark -
#pragma mark ServerConnectionDelegate Methods

-(void)signInComplete
{
    if (!previousSession)
        [self saveSessionWithUsername:self.usernameField.text andPassword:self.passwordField.text];
            
    [self createUserFolders:self.usernameField.text];
    
    //select correct layout
    //TODO: add .xibs for iphone 4 and iPAD
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        
        if ([UIScreen mainScreen].bounds.size.height == 568) {
            self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPhone5" bundle:nil];
            self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone5" bundle:nil];
            self.detectorGalleryController = [[DetectorGalleryViewController alloc]initWithNibName:@"DetectorGalleryViewController" bundle:nil];
            
        }else if ([UIScreen mainScreen].bounds.size.height == 480){
            self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPhone" bundle:nil];
            self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
            self.detectorGalleryController = [[DetectorGalleryViewController alloc]initWithNibName:@"DetectorGalleryViewController" bundle:nil];
        }
        
    }else{
        self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPad" bundle:nil];
        self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPad" bundle:nil];
        self.detectorGalleryController = [[DetectorGalleryViewController alloc]initWithNibName:@"DetectorGalleryViewController" bundle:nil];
    }
   
    //set username
    self.galleryViewController.username = self.usernameField.text;
    self.settingsViewController.username = self.usernameField.text;
    self.detectorGalleryController.username = self.usernameField.text;
    
    //set the tabBar
    self.tabBarController =[[UITabBarController alloc] init];
    self.tabBarController.delegate = self;
    UIViewController *cameraVC = [[UIViewController alloc] init];
    cameraVC.tabBarItem =[[UITabBarItem alloc]initWithTitle:@"Camera" image:nil tag:1];
    [cameraVC.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"camera.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"cameraActive.png"]];
    self.tabBarController.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:self.galleryViewController],
                                              cameraVC,
                                              [[UINavigationController alloc] initWithRootViewController:self.detectorGalleryController],
                                              [[UINavigationController alloc] initWithRootViewController:self.settingsViewController]];
    
    
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.usernameField.text] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    if (![filemng fileExistsAtPath:path]) {
        [sConnection downloadProfilePictureToUsername:self.usernameField.text];
    }
    
    sendingView.hidden = YES;
    [sendingView.activityIndicator stopAnimating];
    [self presentViewController:self.tabBarController animated:YES completion:NULL];
    
    self.userPaths = [self newArrayWithFolders:self.usernameField.text];
    self.userDictionary = [[NSDictionary alloc] initWithContentsOfFile:[[self.userPaths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];

}

-(void)profilePictureReceived:(UIImage *)ppicture
{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.usernameField.text] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    if ([filemng createFileAtPath:path contents:UIImageJPEGRepresentation([ppicture thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil]) {
        [self.settingsViewController.tableView reloadData];
        [self.galleryViewController.profilePicture setImage:ppicture];
    }
}

-(void)signInWithoutConnection
{
    if (previousSession) {
        [self signInComplete];
        
    }else{
        [self errorWithTitle:@"No internet connection" andDescription:@"The app could not connect."];
        [sendingView setHidden:YES];
        [sendingView.activityIndicator stopAnimating];
    }
}


-(void)signInError
{
    //[self.signInButton setEnabled:YES];
    [sendingView setHidden:YES];
}


#pragma mark -
#pragma mark TabBarController Delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{    
    if (tabBarController.selectedIndex == 1) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        
        //detect if camera is available
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        else [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    
        //decide how to present the camera depending if it is iphone or ipad
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
          [tabBarController.selectedViewController presentViewController:imagePicker animated:NO completion:NULL];

        }else{
            if ([imagePicker sourceType] == UIImagePickerControllerSourceTypePhotoLibrary ) {
                if ([self.popover isPopoverVisible]) {
                    [self.popover dismissPopoverAnimated:YES];
                    
                }else{
                    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
                    [popover presentPopoverFromBarButtonItem:[tabBarController.tabBar.items objectAtIndex:1] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES ];
                    
                    self.popover = popover;
                }

            }
            else [tabBarController.selectedViewController presentViewController:imagePicker animated:NO completion:NULL];

        }
    }

}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    //select the xib file to present in function of the device
    TagViewController *tagviewController = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([UIScreen mainScreen].bounds.size.height == 568)
            tagviewController = [[TagViewController alloc] initWithNibName:@"TagViewController_iPhone5" bundle:nil];
        else if ([UIScreen mainScreen].bounds.size.height == 480)
            tagviewController = [[TagViewController alloc] initWithNibName:@"TagViewController_iPhone" bundle:nil];
    } else tagviewController = [[TagViewController alloc] initWithNibName:@"TagViewController_iPad" bundle:nil];
    
    tagviewController.username = self.usernameField.text;
    tagviewController.image = image; //[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [picker setNavigationBarHidden:NO animated:NO];
    
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
        [self.popover dismissPopoverAnimated:NO];
        [tagviewController setHidesBottomBarWhenPushed:YES];
        [self.galleryViewController.navigationController pushViewController:tagviewController animated:YES];
    }else [picker pushViewController:tagviewController animated:YES];
    
    //create a new thread to store image and location information
    dispatch_queue_t myQueue = dispatch_queue_create("saving_image", 0);
    dispatch_async(myQueue, ^{
        [locationMng startUpdatingLocation];
        
        //get the new size of the image according to the defined resolution and save image
        CGSize newSize = image.size;
        BOOL cameraroll = [[self.userDictionary objectForKey:@"cameraroll"] boolValue];
        float resolution = [[self.userDictionary objectForKey:@"resolution"] floatValue];
        float max = newSize.width > newSize.height ? newSize.width : newSize.height;
        if ((resolution != 0.0) && (resolution < max))
            newSize = image.size.height > image.size.width ? CGSizeMake(resolution*0.75, resolution) : CGSizeMake(resolution, resolution*0.75);
        [tagviewController saveImage:[image resizedImage:newSize interpolationQuality:kCGInterpolationHigh]];
        
        if (cameraroll && (picker.sourceType == UIImagePickerControllerSourceTypeCamera ))
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        //save location information
        NSString *location = @"";
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
            location = [[locationMng.location.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""];
        [location writeToFile:[[self.userPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:[[tagviewController.filename stringByDeletingPathExtension] stringByAppendingString:@".txt"]] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        
        [locationMng stopUpdatingLocation];
    });
        
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary))
        [self.popover dismissPopoverAnimated:YES];
        
    else [picker dismissViewControllerAnimated:YES completion:NULL];

}


#pragma mark -
#pragma mark Presenting TagviewController
-(void)presentTagviewControllerWithImage:(UIImage *)image
{
    
}



@end
