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

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //general initialization
        self.filename = [[NSString alloc] init];
        
        //progress view bar
        self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake((frame.size.width-250)/2, (frame.size.height - 20)/2 - 150, 250, 20)];
        self.progressView.progressTintColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];

        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x, self.progressView.frame.origin.y + self.progressView.frame.size.height+10, 20, 20)];
        self.backgroundColor = [UIColor colorWithRed:10/255.0f green:10/255.0f blue:10/255.0f alpha:0.8];
    
        
        //label
//        self.label = [[UILabel alloc] initWithFrame:CGRectMake(self.activityIndicator.frame.origin.x + self.activityIndicator.frame.size.width + 10, self.activityIndicator.frame.origin.y, (self.progressView.frame.size.width - self.activityIndicator.frame.size.width - 20), 100)];

        
        //text view
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0,self.progressView.frame.origin.y + 50,320,300)];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.textAlignment = NSTextAlignmentCenter;
        self.textView.text = @"";
        
        
        //cancel button
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setFrame:CGRectMake(self.progressView.frame.origin.x + self.progressView.frame.size.width/4, self.textView.frame.origin.y + self.textView.frame.size.height+10, self.progressView.frame.size.width/2, 30)];
        [self.cancelButton addTarget:self.delegate action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setBackgroundImage:[UIImage imageNamed:@"navbarBg.png"] forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.cancelButton.tintColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
        self.cancelButton.layer.masksToBounds = YES;
        self.cancelButton.layer.cornerRadius = 10.0;
        
        [self addSubview:self.progressView];
        [self addSubview:self.activityIndicator];
        [self addSubview:self.textView];
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
    if (total>0) [self.textView setText:[NSString stringWithFormat:@"Uploading to LabelMe server... %d/%d",num,total]];
    else [self.textView setText:@"Uploading to LabelMe server..."];
}

-(void)incrementNum
{
    num++;
    if (total>0) [self.textView setText:[NSString stringWithFormat:@"Uploading to LabelMe server... %d/%d",num,total]];
    else [self.textView setText:@"Uploading to LabelMe server..."];
}


-(void)reset
{
    num = 1;
    total =  0;
}


-(void) showMessage:(NSString *)message
{
    NSLog(@"LOG: %@", message);
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        self.textView.text = [self.textView.text stringByAppendingFormat:@"%@\n", message];
        
        //automatic scroll down
        NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
        [self.textView scrollRangeToVisible:range];
    });
}

//-(void)showMessage:(NSString *)message
//{
//    NSLog(@"LOG: %@",message);
//    
//    //messages stack
//    if(self.messagesStack.count > 15) [self.messagesStack removeObjectAtIndex:0];
//    [self.messagesStack addObject:message];
//    
//    NSString *output = @"";
//    for(NSString *message in self.messagesStack)
//        output = [output stringByAppendingString:[NSString stringWithFormat:@"%@\n",message]];
//    
//    [self.label performSelectorOnMainThread:@selector(setText:) withObject:output waitUntilDone:YES];
//}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate cancel];
}


@end
