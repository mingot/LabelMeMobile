//
//  NSObject+Folders.h
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Folders)

-(BOOL)createUserFolders: (NSString *)username;
-(NSArray *) newArrayWithFolders: (NSString *)username;

@end
