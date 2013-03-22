//
//  NSString+checkValidity.h
//  LabelMe
//
//  Created by Dolores on 27/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (checkValidity)

-(BOOL) checkIfContainsOnlyAlphanumericAndUnderscore;
-(BOOL) checkIfContainsOnlyAlphanumericAndUnderscoreWithSpaces;
-(BOOL)checkEmailFormat;
-(NSString *)replaceByUnderscore;


@end
