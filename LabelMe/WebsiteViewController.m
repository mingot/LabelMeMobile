//
//  WebsiteViewController.m
//  LabelMe
//
//  Created by Dolores on 18/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "WebsiteViewController.h"
#import "Reachability.h"
#import "NSObject+ShowAlert.h"

@interface WebsiteViewController ()

@end

@implementation WebsiteViewController
@synthesize website = _website;
@synthesize scrollView = _scrollView;
@synthesize bottomToolbar = _bottomToolbar;
@synthesize back = _back;
@synthesize forward = _forward;
@synthesize reload = _reload;

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
    self.website = [[UIWebView alloc]initWithFrame:self.scrollView.frame];
    [self.website setDelegate:self];
    [self.website sizeToFit];
    [self.website setScalesPageToFit:YES];
    [self.scrollView addSubview:self.website];
    [self.scrollView setDelegate:self];
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    /*[self.bottomToolbar setBackgroundImage:[[UIImage imageNamed:@"navbarBg"]resizableImageWithCapInsets:UIEdgeInsetsZero  ] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.bottomToolbar setTintColor:[UIColor colorWithRed:150/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];*/
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://labelme.csail.mit.edu/Release3.0/browserTools/php/loginiphone.php"]];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [[NSString alloc] initWithFormat:@"multipart/form-data, boundary=%@", boundary ];
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [[NSMutableData alloc]init];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"]  encoding:NSUTF8StringEncoding error:NULL] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"]  encoding:NSUTF8StringEncoding error:NULL] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [theRequest setHTTPBody:postBody];
    [self setTitle:@"LabelMe website"];
    [self.back setImage:[UIImage imageNamed:@"back.png"]];
    [self.forward setImage:[UIImage imageNamed:@"forward.png"]];
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.navigationController.navigationBar.frame.size.width-40), (self.navigationController.navigationBar.frame.size.height-40)/2, 40, 40)];
    [self.navigationController.navigationBar addSubview:activityIndicator];
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if  (networkStatus == NotReachable) {
        [self errorWithTitle:@"No internet connection" andDescription:@"Please, check your connection."];
        [activityIndicator setHidden:YES];
    }
   
       /* NSString *urlAddress = @"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/";
    
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:urlAddress];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    //Load the request in the UIWebView.*/
    [self.website loadRequest:theRequest];
        [self.scrollView setContentSize:self.website.frame.size];

    // Do any additional setup after loading the view from its nib.
}
- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [self.website reload];
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if  (networkStatus == NotReachable) {
        [self errorWithTitle:@"No internet connection" andDescription:@"Please, check your connection."];
    }
}
-(void) viewWillDisappear:(BOOL)animated{
    [self.website stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [activityIndicator stopAnimating];
    [activityIndicator setHidden:YES];
}
#pragma mark -
#pragma mark WebViewDelegate Methods
-(void) webViewDidFinishLoad:(UIWebView *)webView{
    [self.back setEnabled:[webView canGoBack]];
    [self.forward setEnabled:[webView canGoForward]];
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [activityIndicator stopAnimating];
    [activityIndicator setHidden:YES];
   


}
-(void) webViewDidStartLoad:(UIWebView *)webView{
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
}
#pragma mark -
#pragma mark ScrollViewDelegate Methods
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView {
    return self.website;
}
#pragma mark -
#pragma mark IBAction Methods

-(IBAction)goBack:(id)sender{
    [self.website goBack];
    
}
-(IBAction)goForward:(id)sender{
    [self.website goForward];
    
}
-(IBAction)reload:(id)sender{
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
    [self.website reload];
}
#pragma mark -
#pragma mark Memory Management Methods
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc{
    self.back;
    self.forward;
    self.reload;
    self.bottomToolbar;
    self.website;
    self.scrollView;
}

@end
