//
//  AppDelegate.m
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "LabelMeAppDelegate.h"
#import "SignInViewController.h"

#define BACKGROUND_COLOR [UIColor colorWithRed:230/256.0 green:230/256.0 blue:230/256.0 alpha:1];

@implementation LabelMeAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    //Decide which device it is using it (iphone, iphone5 or ipad)
    SignInViewController *rootViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPhone" bundle:nil];
    }else rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPad" bundle:nil];


    
    //navigation bar definition for all the application
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:193/256.0 green:39/256.0 blue:45/256.0 alpha:1.0]];
//    [[UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil] setTintColor:[UIColor redColor]];
    
    //BACK BUTTON DEFINITION
    UIImage *backButtonImage = [[UIImage imageNamed:@"backButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
//    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    
//    //Other menu butotns
//    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"backButton.png"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}


@end




