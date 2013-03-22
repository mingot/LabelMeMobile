//
//  AppDelegate.m
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "LabelMeAppDelegate.h"
#import "SignInViewController.h"

@implementation LabelMeAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

   
    //[application setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    SignInViewController *rootViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CGRect screenSize = [[UIScreen mainScreen] bounds];

        if (screenSize.size.height == 568) {

            rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPhone5" bundle:nil];
            self.window.rootViewController = rootViewController;
        }
        else if (screenSize.size.height == 480){

            rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPhone" bundle:nil];
            self.window.rootViewController = rootViewController;
        }
        
        
        
    }
    else{

        rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPad" bundle:nil];
        self.window.rootViewController = rootViewController;
        
    }
    [self.window makeKeyAndVisible];
    return YES;
}


@end
