//
//  WebsiteViewController.h
//  LabelMe
//
//  Created by Dolores on 18/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebsiteViewController : UIViewController <UIScrollViewDelegate,UIWebViewDelegate>

@property (nonatomic,weak) IBOutlet UIWebView *website;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) IBOutlet UIToolbar *bottomToolbar;
@property (weak, nonatomic,readonly) IBOutlet UIBarButtonItem *back;
@property (weak, nonatomic,readonly) IBOutlet UIBarButtonItem *forward;
@property (weak, nonatomic,readonly) IBOutlet UIBarButtonItem *reload;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

-(IBAction)goBack:(id)sender;
-(IBAction)goForward:(id)sender;
-(IBAction)reload:(id)sender;

@end
