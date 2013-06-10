//
//  SendingView.m
//  LabelMe
//
//  Created by Dolores on 02/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "SendingView.h"
#import <QuartzCore/QuartzCore.h>


@interface SendingView()
{
    int total;
    int num;
}

@end



@implementation SendingView

- (id)initWithFrame:(CGRect)frame
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"sendingView" owner:self options:nil] objectAtIndex:0];
    if (self) {
        
        //set super frame
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        
        //text view
        self.textView.text = @"";
        
        //cancel button
        self.cancelButton.tintColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
        self.cancelButton.layer.masksToBounds = YES;
        self.cancelButton.layer.cornerRadius = 10.0;
        
        num = 1;
        total = 0;
    }
    return self;
}


-(void)setTotal:(int)i
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

- (void) clearScreen
{
    [self.textView performSelectorOnMainThread:@selector(setText:) withObject:@"" waitUntilDone:YES];

}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate cancel];
}


@end
