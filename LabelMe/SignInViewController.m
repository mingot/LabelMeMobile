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
#import "UIViewController+ShowAlert.h"
#import "NSObject+Folders.h"
#import "NSString+checkValidity.h"

#import "LMUINavigationController.h"



@interface SignInViewController()

//keyboard
-(void)keyboardDidShow:(NSNotification *)notif;
-(void)keyboardDidHide:(NSNotification *)notif;

@end



@implementation SignInViewController


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
    
    //textfields
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
    
    //sending view
    self.sendingView = [[SendingView alloc] initWithFrame:self.view.frame];
    self.sendingView.delegate = self;
    [self.sendingView.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.sendingView.hidden = YES;
    self.sendingView.progressView.hidden = YES;
    self.sendingView.textView.text = @"Signing in...";
    [self.view addSubview:self.sendingView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    [self.usernameField setText:@""];
    [self.passwordField setText:@""];
    previousSession = [self rememberMe];   
    
    // Register keyboard events
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
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
}


#pragma mark -
#pragma mark Keyboard Events

-(void)keyboardDidShow:(NSNotification *)notif
{    
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
    [self.scrollView scrollRectToVisible:self.passwordField.frame animated:YES];
}


-(void)keyboardDidHide:(NSNotification *)notif
{    
    self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y, self.scrollView.frame.size.width, self.view.frame.size.height);
}


#pragma mark -
#pragma mark IBActions 

-(IBAction)signInAction:(id)sender
{

    [self cancelAction:nil];
    [self.sendingView setHidden:NO];
    [self.sendingView.activityIndicator startAnimating];

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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
        createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPhone" bundle:nil];
    else createAccountViewController = [[CreateAccountViewController alloc]initWithNibName:@"CreateAccountViewController_iPad" bundle:nil];

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
    if (textField == self.passwordField) [self nextFieldAction:nil];
    else if (textField == self.usernameField) [self previousAction:nil];
    
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
    [self.sendingView setHidden:YES];
    [self.sendingView.activityIndicator stopAnimating];
}


#pragma mark -
#pragma mark ServerConnectionDelegate Methods

-(void)signInComplete
{
    if (!previousSession)
        [self saveSessionWithUsername:self.usernameField.text andPassword:self.passwordField.text];
            
    [self createUserFolders:self.usernameField.text];
    
    //select correct layout
    self.galleryViewController =[[GalleryViewController alloc]initWithNibName:@"GalleryViewController_iPhone" bundle:nil];
    self.settingsViewController = [[SettingsViewController alloc]initWithNibName:@"SettingsViewController_iPhone" bundle:nil];
    self.detectorGalleryController = [[DetectorGalleryViewController alloc]initWithNibName:@"DetectorGalleryViewController" bundle:nil];

    //set username
    self.galleryViewController.username = self.usernameField.text;
    self.settingsViewController.username = self.usernameField.text;
    self.detectorGalleryController.username = self.usernameField.text;
    
    //set the tabBar
    self.tabBarController =[[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:self.galleryViewController], [[UINavigationController alloc] initWithRootViewController:self.detectorGalleryController],[[UINavigationController alloc] initWithRootViewController:self.settingsViewController]];
    
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.usernameField.text] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [sConnection downloadProfilePictureToUsername:self.usernameField.text];
    }

    
    self.sendingView.hidden = YES;
    [self.sendingView.activityIndicator stopAnimating];
    [self presentViewController:self.tabBarController animated:YES completion:NULL];
    
    //transferring paths to galleryVC
    self.galleryViewController.userPaths = [self newArrayWithFolders:self.usernameField.text];
}

-(void)profilePictureReceived:(UIImage *)ppicture
{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.usernameField.text] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    if ([filemng createFileAtPath:path contents:UIImageJPEGRepresentation([ppicture thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil]) {
        [self.settingsViewController.tableView reloadData];
    }
}

-(void)signInWithoutConnection
{
    if (previousSession) [self signInComplete];
    else{
        [self errorWithTitle:@"No internet connection" andDescription:@"The app could not connect."];
        [self.sendingView setHidden:YES];
        [self.sendingView.activityIndicator stopAnimating];
    }
}


-(void)signInError
{
    [self.sendingView setHidden:YES];
}




@end
