//
//  WriteToFileAndUpdateCounter.h
//  TestDetector
//
//  Created by Josep Marc Mingot Hidalgo on 03/02/13.
//  Copyright (c) 2013 Dolores. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileStorageHelper : NSObject

+ (NSString *) getPathForCurrentFileAndUpdateCounter:(NSString *)file;
+ (double *) readTemplate:(NSString *)filename;
+ (void) writeImageToDisk:(CGImageRef)image withTitle:(NSString *)title;


// For storing data

+ (void)writeTemplate:(double *)vect withSize:(int *)size withTitle:(NSString *) filename;
+ (void)writeImage:(UInt8 *)vect withSize:(int *)size withTitle:(NSString *) filename;
+ (void)write:(double *)vect withSize:(int *)size withTitle:(NSString *) filename;
+ (void)writeImages:(UInt8 *)vect withSize:(int *)size withTitle:(NSString *) filename;
+ (void)writeConv:(double *)vect withSize:(int *)size withTitle:(NSString *) filename;
+ (void)writeConvWithArray:(NSArray *)conv withSize:(int *)size withTitle:(NSString *) filename;


@end
