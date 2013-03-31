//
//  CreateAccountViewController.m
//  LabelMe
//
//  Created by Dolores on 27/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "CreateAccountViewController.h"
#import "NSString+checkValidity.h"
#import "NSObject+ShowAlert.h"
#import "NSObject+Folders.h"

@interface CreateAccountViewController ()

@end

@implementation CreateAccountViewController
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize biologicalNameField = _biologicalNameField;
@synthesize emailField = _emailField;
@synthesize institutionField = _institutionField;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize topToolbar = _topToolBar;
@synthesize scrollView = _scrollView;
@synthesize tabBarController = _tabBarController;
#pragma mark -
#pragma mark Initialitation
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(createAccountAction:)];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction:)];
    doneButton.enabled = NO;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.keyboardToolbar setItems:[NSArray arrayWithObjects:previousButton,nextButton,flexibleSpace,cancelButton, doneButton,nil]];
    self.usernameField.inputAccessoryView = self.keyboardToolbar;
    self.passwordField.inputAccessoryView = self.keyboardToolbar;
    self.biologicalNameField.inputAccessoryView = self.keyboardToolbar;
    self.emailField.inputAccessoryView = self.keyboardToolbar;
    self.institutionField.inputAccessoryView = self.keyboardToolbar;
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    self.biologicalNameField.delegate = self;
    self.emailField.delegate = self;
    self.institutionField.delegate = self;

    self.passwordField.secureTextEntry = YES;
    
    [self.scrollView setContentSize:self.scrollView.frame.size];
    UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"] ;
    [self.topToolbar setBackgroundImage:barImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.topToolbar setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    UIImage *titleImage = [UIImage imageNamed:@"labelmelogo-shadow.png"];
    UIImageView *labelmeView = [[UIImageView alloc] initWithImage:titleImage];
    [labelmeView setFrame:CGRectMake((self.view.frame.size.width-labelmeView.frame.size.width)/2, 10, labelmeView.frame.size.width, labelmeView.frame.size.height)];
    [self.scrollView addSubview:labelmeView];
    

}
#pragma mark -
#pragma mark Views Appear

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // Register keyboard events
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    keyboardVisible = NO;
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    // Unregister keyboard events
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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
    CGRect viewFrame = self.scrollView.frame;
	viewFrame.size.height = keyboardTop - self.view.bounds.origin.y +self.topToolbar.frame.size.height;
	
	self.scrollView.frame = viewFrame;
	keyboardVisible = YES;
    
    
    
    
}
-(void)keyboardDidHide:(NSNotification *)notif{
    
    if (!keyboardVisible) {
        return;
    }
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y = self.scrollView.frame.origin.y;
    viewFrame.size.height = viewFrame.size.height - self.topToolbar.frame.size.height;
    self.scrollView.frame = viewFrame;
    keyboardVisible = NO;
}
#pragma mark -
#pragma mark IBActions

-(IBAction)createAccountAction:(id)sender{
    if ([self checkValidity]) {
        ServerConnection *serverConnection = [[ServerConnection alloc]init];
        serverConnection.delegate = self;
        NSArray *fields = [[NSArray alloc] initWithObjects:self.biologicalNameField.text,self.institutionField.text,self.usernameField.text,self.passwordField.text,self.emailField.text, nil];
        [serverConnection createAccountWithFields:fields];
       // [self dismissViewControllerAnimated:YES completion:NULL];
        
    }
    else{
        [self errorWithTitle:@"" andDescription:@"Please, check the fields. Only letters and numbers allowed."];

    }
}
-(IBAction)cancelButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
-(IBAction)nextFieldAction:(id)sender{
    UIBarButtonItem * nextButton = [[self.keyboardToolbar items] objectAtIndex:1];
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    switch (currentTextField.tag) {
        case 0:
            nextButton.enabled = YES;
            previousButton.enabled = YES;
            [self.passwordField becomeFirstResponder];
            break;
        case 1:
            nextButton.enabled = YES;
            previousButton.enabled = YES;
            [self.biologicalNameField becomeFirstResponder];
            break;
        case 2:
            nextButton.enabled = YES;
            previousButton.enabled = YES;
            [self.emailField becomeFirstResponder];
            break;
        case 3:
            nextButton.enabled = NO;
            previousButton.enabled = YES;
            [self.institutionField becomeFirstResponder];
            break;
            
            
        default:
            break;
    }
}
-(IBAction)previousAction:(id)sender{
    UIBarButtonItem * nextButton = [[self.keyboardToolbar items] objectAtIndex:1];
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    switch (currentTextField.tag) {
            
        case 1:
            nextButton.enabled = YES;
            previousButton.enabled = NO;
            [self.usernameField becomeFirstResponder];
            break;
        case 2:
            nextButton.enabled = YES;
            previousButton.enabled = YES;
            [self.passwordField becomeFirstResponder];
            break;
        case 3:
            nextButton.enabled = YES;
            previousButton.enabled = YES;
            [self.biologicalNameField becomeFirstResponder];
            break;
        case 4:
            nextButton.enabled = YES;
            previousButton.enabled = YES;
            [self.emailField becomeFirstResponder];
            break;
            
            
        default:
            break;
    }

    
}
-(IBAction)cancelAction:(id)sender{
    
    [currentTextField resignFirstResponder];

    
}
-(IBAction)valueChanged:(id)sender{
    UIBarButtonItem * doneButton = [[self.keyboardToolbar items] objectAtIndex:4];
    
    if ((self.passwordField.text.length*self.usernameField.text.length*self.biologicalNameField.text.length*self.emailField.text.length*self.institutionField.text.length)==0) {
        [doneButton setEnabled:NO];
    }
    else{
        [doneButton setEnabled:YES];
    }
    
}
#pragma mark -
#pragma mark Previous Session Methods


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
#pragma mark -
#pragma mark Check Fields Validity

-(BOOL)checkValidity{
    if ([self.usernameField.text checkIfContainsOnlyAlphanumericAndUnderscore] ) {
        if ([self.passwordField.text checkIfContainsOnlyAlphanumericAndUnderscore] ) {
            if ([self.biologicalNameField.text checkIfContainsOnlyAlphanumericAndUnderscoreWithSpaces] ) {
                if ([self.emailField.text checkEmailFormat] ) {
                    if ([self.institutionField.text checkIfContainsOnlyAlphanumericAndUnderscoreWithSpaces] ) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Text Field Delegate Methods
-(void)textFieldDidBeginEditing:(UITextField *)textField{
    currentTextField = textField;
    UIBarButtonItem * nextButton = [[self.keyboardToolbar items] objectAtIndex:1];
    UIBarButtonItem * previousButton = [[self.keyboardToolbar items] objectAtIndex:0];
    if (currentTextField.tag == 4) {
        nextButton.enabled = NO;
        previousButton.enabled = YES;
    }
    else if(currentTextField.tag == 0){
        nextButton.enabled = YES;
        previousButton.enabled = NO;
        
    }
    else{
        nextButton.enabled = YES;
        previousButton.enabled = YES;
    }

}
#pragma mark -
#pragma mark ServerConnectionDelegate Methods
-(void)createAccountComplete{
    if ([self saveSessionWithUsername:self.usernameField.text andPassword:self.passwordField.text]) {
        [self createUserFolders:self.usernameField.text];
        [self dismissViewControllerAnimated:YES completion:NULL];
        [self.delegate signIn];

    }
    else{
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
        
    


}
-(void)createAccountError{
}


@end
