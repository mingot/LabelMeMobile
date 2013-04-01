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

    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    //Decide which device it is using it (iphone, iphone5 or ipad)
    SignInViewController *rootViewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([UIScreen mainScreen].bounds.size.height == 568)
            rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPhone5" bundle:nil];

        else if ([UIScreen mainScreen].bounds.size.height == 480)
            rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPhone" bundle:nil];
        
    }else
        rootViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController_iPad" bundle:nil];

    
    self.window.rootViewController = rootViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}


@end
