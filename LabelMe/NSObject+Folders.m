//
//  NSObject+Folders.m
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "NSObject+Folders.h"

@implementation NSObject (Folders)

-(BOOL)createUserFolders: (NSString *)username{
    NSFileManager * filemng = [NSFileManager defaultManager];

    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // change to accomodate user
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,username ];
    NSArray *paths = [[NSArray alloc] initWithObjects:[path stringByAppendingPathComponent:@"images"],[path stringByAppendingPathComponent:@"thumbnail"],[path stringByAppendingPathComponent:@"annotations"], nil];
    
    //Create directories
    
    BOOL isDir = YES;
    if (![filemng fileExistsAtPath:path isDirectory:&isDir]) {
        
            if([filemng createDirectoryAtPath:[NSString stringWithFormat:@"%@",path] withIntermediateDirectories:YES attributes:nil error:NULL]){
            }
            else return NO;

    }
    if (![filemng fileExistsAtPath:[paths objectAtIndex:0] isDirectory:&isDir]) {

            if([filemng createDirectoryAtPath:[paths objectAtIndex:0] withIntermediateDirectories:YES attributes:nil error:NULL]){
            }
            else return NO;
            
    }
    if (![filemng fileExistsAtPath:[paths objectAtIndex:1] isDirectory:&isDir]) {
        
            if([filemng createDirectoryAtPath:[paths objectAtIndex:1] withIntermediateDirectories:YES attributes:nil error:NULL]){
            }
            else return NO;
    
    }
    if (![filemng fileExistsAtPath:[paths objectAtIndex:2] isDirectory:&isDir]) {
        
            if([filemng createDirectoryAtPath:[paths objectAtIndex:2] withIntermediateDirectories:YES attributes:nil error:NULL]){
            }
            else return NO;
    }
    isDir = NO;
    if (![filemng fileExistsAtPath:[path stringByAppendingFormat:@"/%@.plist",username] isDirectory:&isDir]) {
        
        NSDictionary *dict = [[NSDictionary alloc] init];
        [dict writeToFile:[path stringByAppendingFormat:@"/%@.plist",username] atomically:NO];
        
    }
    if (![filemng fileExistsAtPath:[path stringByAppendingString:@"/settings.plist"] isDirectory:&isDir]) {
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:username forKey:@"username"];
        [dict setObject:@"" forKey:@"datesignup"];
        [dict setObject:@"" forKey:@"institution"];
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"cameraroll"];
        [dict setObject:[NSNumber numberWithFloat:0] forKey:@"resolution"];
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"wifi"];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"signinauto"];
        [dict writeToFile:[path stringByAppendingString:@"/settings.plist"] atomically:YES];
        
    }

    
    return YES;
}

-(NSArray *) newArrayWithFolders: (NSString *)username
{
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,username ];

    NSArray *paths = [NSArray arrayWithObjects:[path stringByAppendingPathComponent:@"images"],[path stringByAppendingPathComponent:@"thumbnail"],[path stringByAppendingPathComponent:@"annotations"],path, nil];
    return paths;
}


@end
