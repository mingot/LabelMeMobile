//
//  NSObject+ShowAlert.m
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "NSObject+ShowAlert.h"

@implementation NSObject (ShowAlert)

-(void)errorWithTitle: (NSString *)title andDescription: (NSString *)description{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:description delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

@end
