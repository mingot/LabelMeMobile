//
//  LogVC.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "LogVC.h"



@implementation LogVC



- (void)viewDidLoad
{
    [super viewDidLoad];
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
