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



@interface CreateAccountViewController : UIViewController <UITextFieldDelegate, ServerConnectionDelegate>
{
    BOOL keyboardVisible;
    UITextField* currentTextField;
}


@property (nonatomic,strong) id <CreateAccountDelegate> delegate;
@property (nonatomic,strong) IBOutlet UITextField *usernameField;
@property (nonatomic,strong) IBOutlet UITextField *passwordField;
@property (nonatomic,strong) IBOutlet UITextField *biologicalNameField;
@property (nonatomic,strong) IBOutlet UITextField *emailField;
@property (nonatomic,strong) IBOutlet UITextField *institutionField;
@property (nonatomic,strong) IBOutlet UIToolbar   *topToolbar;
@property (nonatomic,strong) IBOutlet UIScrollView   *scrollView;

@property (nonatomic,strong) UIToolbar  *keyboardToolbar;

@property (nonatomic,strong) UITabBarController   *tabBarController;


-(void)keyboardDidShow:(NSNotification *)notif;
-(void)keyboardDidHide:(NSNotification *)notif;
-(IBAction)valueChanged:(id)sender;
-(IBAction)createAccountAction:(id)sender;
-(IBAction)cancelButtonAction:(id)sender;
-(IBAction)nextFieldAction:(id)sender;
-(IBAction)previousAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end
