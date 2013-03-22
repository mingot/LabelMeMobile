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
    UIBarButtonItem *__weak _back;
    UIBarButtonItem *__weak _forward;
    UIBarButtonItem *__weak _reload;
    UIActivityIndicatorView *activityIndicator;
}
@property (nonatomic,strong)  UIWebView *website;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic,strong) IBOutlet UIToolbar *bottomToolbar;
@property (weak, nonatomic,readonly) IBOutlet UIBarButtonItem *back;
@property (weak, nonatomic,readonly) IBOutlet UIBarButtonItem *forward;
@property (weak, nonatomic,readonly) IBOutlet UIBarButtonItem *reload;

-(IBAction)goBack:(id)sender;
-(IBAction)goForward:(id)sender;
-(IBAction)reload:(id)sender;

@end
