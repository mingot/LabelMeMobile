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



@implementation WebsiteViewController


@synthesize back = _back;
@synthesize forward = _forward;
@synthesize reload = _reload;



- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"LabelMe website"];
    
    [self.website sizeToFit];
    [self.website setScalesPageToFit:YES];
    
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;

    //post request to log in
    NSString *boundary = @"AaB03x";
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
    

    [self.back setImage:[UIImage imageNamed:@"back.png"]];
    [self.forward setImage:[UIImage imageNamed:@"forward.png"]];
    
    //Load the request in the UIWebView.

    [self.website loadRequest:theRequest];
    [self.scrollView setContentSize:self.website.frame.size];


}
- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.website reload];
    
    //reachability
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if  (networkStatus == NotReachable) {
        [self errorWithTitle:@"No internet connection" andDescription:@"Please, check your connection."];
        [self.activityIndicator setHidden:YES];
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    [self.website stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
}

#pragma mark -
#pragma mark WebViewDelegate Methods

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [self.back setEnabled:[webView canGoBack]];
    [self.forward setEnabled:[webView canGoForward]];
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:YES];
}

-(void) webViewDidStartLoad:(UIWebView *)webView
{
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
}


#pragma mark -
#pragma mark ScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)aScrollView
{
    return self.website;
}


#pragma mark -
#pragma mark IBAction Methods

-(IBAction)goBack:(id)sender
{
    [self.website goBack];
}

-(IBAction)goForward:(id)sender
{
    [self.website goForward];
}

-(IBAction)reload:(id)sender
{
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
    [self.activityIndicator setHidden:NO];
    [self.website reload];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}
@end
