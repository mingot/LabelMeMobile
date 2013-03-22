//
//  WebsiteViewController.h
//  LabelMe
//
//  Created by Dolores on 18/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebsiteViewController : UIViewController <UIScrollViewDelegate,UIWebViewDelegate>{
    UIWebView *_website;
    UIScrollView *_scrollView;
    UIToolbar *_bottomToolbar;
    UIBarButtonItem *_back;
    UIBarButtonItem *_forward;
    UIBarButtonItem *_reload;
    UIActivityIndicatorView *activityIndicator;
}
@property (nonatomic,retain)  UIWebView *website;
@property (nonatomic,retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic,retain) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic,readonly) IBOutlet UIBarButtonItem *back;
@property (nonatomic,readonly) IBOutlet UIBarButtonItem *forward;
@property (nonatomic,readonly) IBOutlet UIBarButtonItem *reload;

-(IBAction)goBack:(id)sender;
-(IBAction)goForward:(id)sender;
-(IBAction)reload:(id)sender;

@end
