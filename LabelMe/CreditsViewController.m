//
//  CreditsViewController.m
//  LabelMe
//
//  Created by Dolores on 20/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "CreditsViewController.h"

@interface CreditsViewController ()

@end

@implementation CreditsViewController

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
    UIImage *titleImage = [UIImage imageNamed:@"labelmelogo-shadow.png"];
    UIImageView *labelmeView = [[UIImageView alloc] initWithImage:titleImage];
    [labelmeView setFrame:CGRectMake((self.view.frame.size.width-labelmeView.frame.size.width)/2, 10, labelmeView.frame.size.width, labelmeView.frame.size.height)];
    [self.scrollView addSubview:labelmeView];
    UILabel *information = [[UILabel alloc] initWithFrame:CGRectMake(0.0625*self.view.frame.size.width, 0.0625*self.view.frame.size.width+labelmeView.frame.size.height, self.view.frame.size.width-0.125*self.view.frame.size.width, self.scrollView.frame.size.height - labelmeView.frame.size.height-0.125*self.view.frame.size.width)];
    [information setTextAlignment:NSTextAlignmentCenter];
    [information setNumberOfLines:0];
    [information setBackgroundColor:[UIColor clearColor]];
    [information setLineBreakMode:UILineBreakModeWordWrap];
    NSString *informationString = [[NSString alloc]initWithString:@"Version 1.0, 2012\n\nThe goal of LabelMe is to provide an image annotation tool for computer vision research. \n\nImages uploaded to the server will be available at labelme.csail.mit.edu where other people can see your images and annotations.\n\nFor suggestions send email to labelme@csail.mit.edu\n\nDeveloped at the Computer Science and Artificial Intelligence Laboratory at MIT by:\n\nDolores Blanco\nAina Torralba\nDavid Way\nAntonio Torralba\n\n© LabelMe"];
    [information setText:informationString];
    CGSize expectedLabelSize = [informationString sizeWithFont:information.font constrainedToSize:CGSizeMake(information.frame.size.width, 2000) lineBreakMode:UILineBreakModeWordWrap];
    [information setFrame:CGRectMake(information.frame.origin.x, information.frame.origin.y,expectedLabelSize.width, expectedLabelSize.height)];
    [information setTextColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
   /* information.shadowColor = [UIColor grayColor];
    information.shadowOffset = CGSizeMake(0.0, 1.0);*/
    [self.scrollView addSubview:information];
    [self.scrollView setCanCancelContentTouches:NO];
	self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    [self.scrollView setScrollEnabled:YES];
    self.scrollView.clipsToBounds = YES;
	self.scrollView.scrollEnabled = YES;
	self.scrollView.pagingEnabled = NO;
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, labelmeView.frame.size.height+information.frame.size.height+0.125*self.view.frame.size.width
                                               )];
    UIImage *logoImage = [UIImage imageNamed:@"MITLogo.gif"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logoImage];
    [logoView setFrame:CGRectMake((self.view.frame.size.width-logoView.frame.size.width)/2,  labelmeView.frame.size.height+information.frame.size.height+0.125*self.view.frame.size.width, logoView.frame.size.width, logoView.frame.size.height)];
    [self.scrollView addSubview:logoView];
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, labelmeView.frame.size.height+information.frame.size.height+0.125*self.view.frame.size.width+logoView.frame.size.height
                                               )];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)dealloc{
    self.scrollView;
    
}
@end
