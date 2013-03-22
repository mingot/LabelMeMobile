//
//  NSObject+ShowAlert.h
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (ShowAlert)

-(void)errorWithTitle: (NSString *)title andDescription: (NSString *)description;

@end
