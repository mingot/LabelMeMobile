//
//  SendingView.m
//  LabelMe
//
//  Created by Dolores on 02/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "SendingView.h"
#import <QuartzCore/QuartzCore.h>


@implementation SendingView
@synthesize progressView = _progressView;
@synthesize activityIndicator = _activityIndicator;
@synthesize label = _label;
@synthesize filename = _filename;
@synthesize cancelButton = _cancelButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"] ;

        self.filename = [[NSString alloc] init];
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake((frame.size.width-250)/2, (frame.size.height -20)/2, 250, 20)];
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x, self.progressView.frame.origin.y+self.progressView.frame.size.height+10, 20, 20)];
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(self.activityIndicator.frame.origin.x+self.activityIndicator.frame.size.width+10, self.activityIndicator.frame.origin.y, (self.progressView.frame.size.width-self.activityIndicator.frame.size.width-20), 50)];
        [self.label setNumberOfLines:2];
        //self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(self.label.frame.origin.x, self.label.frame.origin.y + self.label.frame.size.height+10, self.label.frame.size.width, 20)];
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setFrame:CGRectMake(self.progressView.frame.origin.x + self.progressView.frame.size.width/4, self.label.frame.origin.y + self.label.frame.size.height+20, self.progressView.frame.size.width/2, 30)];
        [self.cancelButton addTarget:self.delegate action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        //[self.cancelButton setBackgroundColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
        [self.cancelButton setBackgroundImage:barImage forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.cancelButton setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
        self.cancelButton.layer.masksToBounds = YES;
        self.cancelButton.layer.cornerRadius = 10.0;
        [self setBackgroundColor:[UIColor colorWithRed:10/255.0f green:10/255.0f blue:10/255.0f alpha:0.8]];
        [self.label setBackgroundColor:[UIColor clearColor]];
        [self.label setTextColor:[UIColor whiteColor]];
        [self.label setText:@"Uploading to LabelMe server..."];
        [self.label setTextAlignment:NSTextAlignmentCenter];
        [self.progressView setProgressTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
        [self addSubview:self.progressView];
        [self addSubview:self.activityIndicator];
        [self addSubview:self.label];
        [self addSubview:self.cancelButton];
        num = 1;
        total = 0;

    
    }
    return self;
}
-(void)setTotal:(int) i{
    total=i;
    if (total>0) {
        [self.label setText:[NSString stringWithFormat:@"Uploading to LabelMe server... %d/%d",num,total]];
    }
    else{
        [self.label setText:@"Uploading to LabelMe server..."];

    }
}
-(void)incrementNum{
    num++;
    if (total>0) {
        [self.label setText:[NSString stringWithFormat:@"Uploading to LabelMe server... %d/%d",num,total]];
    }
    else{
        [self.label setText:@"Uploading to LabelMe server..."];

    }
    
}
-(void)reset{
    num = 1;
    total =  0;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
-(void)dealloc{
    [self.label release];
    [self.progressView release];
    [self.activityIndicator release];
    [self.filename release];
    [self.cancelButton release];
    [super dealloc];
}

@end
