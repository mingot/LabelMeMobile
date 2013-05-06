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
@synthesize messagesStack = _messagesStack;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //general initialization
        UIImage *barImage = [UIImage imageNamed:@"navbarBg.png"] ;
        self.filename = [[NSString alloc] init];
        
        //progress view bar
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake((frame.size.width-250)/2, (frame.size.height - 20)/2 - 150, 250, 20)];
        self.progressView.progressTintColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];

        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x, self.progressView.frame.origin.y + self.progressView.frame.size.height+10, 20, 20)];
        self.backgroundColor = [UIColor colorWithRed:10/255.0f green:10/255.0f blue:10/255.0f alpha:0.8];
    
        
        //label
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(
                                            self.activityIndicator.frame.origin.x + self.activityIndicator.frame.size.width + 10,
                                            self.activityIndicator.frame.origin.y,
                                            (self.progressView.frame.size.width - self.activityIndicator.frame.size.width - 20),
                                            100)];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.numberOfLines = 0;
        self.label.frame = CGRectMake(20,20,300,400);
        self.label.font = [UIFont fontWithName:@"AmericanTypewriter" size:10];
        
        //cancel button
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setFrame:CGRectMake(self.progressView.frame.origin.x + self.progressView.frame.size.width/4, self.label.frame.origin.y + self.label.frame.size.height+10, self.progressView.frame.size.width/2, 30)];
        [self.cancelButton addTarget:self.delegate action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setBackgroundImage:barImage forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.cancelButton.tintColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
        self.cancelButton.layer.masksToBounds = YES;
        self.cancelButton.layer.cornerRadius = 10.0;
        
        [self addSubview:self.progressView];
        [self addSubview:self.activityIndicator];
        [self addSubview:self.label];
        [self addSubview:self.cancelButton];
        
        num = 1;
        total = 0;
        self.messagesStack = [[NSMutableArray alloc] init];
    }
    return self;
}


-(void)setTotal:(int) i
{
    total=i;
    if (total>0) [self.label setText:[NSString stringWithFormat:@"Uploading to LabelMe server... %d/%d",num,total]];
    else [self.label setText:@"Uploading to LabelMe server..."];
}

-(void)incrementNum
{
    num++;
    if (total>0) [self.label setText:[NSString stringWithFormat:@"Uploading to LabelMe server... %d/%d",num,total]];
    else [self.label setText:@"Uploading to LabelMe server..."];
}


-(void)reset
{
    num = 1;
    total =  0;
}


-(void)showMessage:(NSString *)message
{
    NSLog(@"LOG: %@",message);
    
    //messages stack
    if(self.messagesStack.count > 15) [self.messagesStack removeObjectAtIndex:0];
    [self.messagesStack addObject:message];
    
    NSString *output = @"";
    for(NSString *message in self.messagesStack)
        output = [output stringByAppendingString:[NSString stringWithFormat:@"%@\n",message]];
    
    [self.label performSelectorOnMainThread:@selector(setText:) withObject:output waitUntilDone:YES];
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate cancel];
}


@end
