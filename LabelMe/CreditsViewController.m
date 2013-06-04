//
//  CreditsViewController.m
//  LabelMe
//
//  Created by Dolores on 20/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "CreditsViewController.h"



@implementation CreditsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //adjust size of text view to fit contents
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.contentSize.height);
    
    //set scroll view content size
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width,
                                               self.titleView.frame.size.height + self.textView.frame.size.height + self.logoView.frame.size.height)];
    
    //reajust the logo in the content size
    self.logoView.frame = CGRectMake(self.logoView.frame.origin.x, self.titleView.frame.size.height + self.textView.frame.size.height, self.logoView.frame.size.width, self.logoView.frame.size.height);
}



- (void)viewDidUnload
{
    [self setTextView:nil];
    [self setLogoView:nil];
    [super viewDidUnload];
}

@end
