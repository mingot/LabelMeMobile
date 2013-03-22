//
//  CreateAccountViewController.h
//  LabelMe
//
//  Created by Dolores on 27/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerConnection.h"
@protocol CreateAccountDelegate <NSObject>

@optional
-(void)signIn;


@end

@interface CreateAccountViewController : UIViewController <UITextFieldDelegate, ServerConnectionDelegate>{
    
    
     UITextField    *_usernameField;
     UITextField    *_passwordField;
     UITextField    *_biologicalNameField;
     UITextField    *_emailField;
     UITextField    *_institutionField;
     UIToolbar      *_topToolBar;
     UIScrollView   *_scrollView;
    UIToolbar               *_keyboardToolbar;
    
    BOOL                      keyboardVisible;
    UITextField             * currentTextField;
    UITabBarController      *_tabBarController;
    
    
    
    
}
@property (nonatomic,retain) id <CreateAccountDelegate> delegate;
@property (nonatomic,retain) IBOutlet UITextField *usernameField;
@property (nonatomic,retain) IBOutlet UITextField *passwordField;
@property (nonatomic,retain) IBOutlet UITextField *biologicalNameField;
@property (nonatomic,retain) IBOutlet UITextField *emailField;
@property (nonatomic,retain) IBOutlet UITextField *institutionField;
@property (nonatomic,retain) IBOutlet UIToolbar   *topToolbar;
@property (nonatomic,retain) IBOutlet UIScrollView   *scrollView;

@property (nonatomic,retain) UIToolbar  *keyboardToolbar;

@property (nonatomic,retain) UITabBarController   *tabBarController;


#pragma mark -
#pragma mark Methods

-(void)keyboardDidShow:(NSNotification *)notif;
-(void)keyboardDidHide:(NSNotification *)notif;
-(IBAction)valueChanged:(id)sender;
-(IBAction)createAccountAction:(id)sender;
-(IBAction)cancelButtonAction:(id)sender;
-(IBAction)nextFieldAction:(id)sender;
-(IBAction)previousAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
