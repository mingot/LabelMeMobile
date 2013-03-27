//
//  WriteToFileAndUpdateCounter.m
//  TestDetector
//
//  Created by Josep Marc Mingot Hidalgo on 03/02/13.
//  Copyright (c) 2013 Dolores. All rights reserved.
//

#import "FileStorageHelper.h"
#import "ConvolutionHelper.h"  // For convolution point 

@implementation FileStorageHelper : NSObject 

+ (NSString *) getPathForCurrentFileAndUpdateCounter:(NSString *)file
{
    // write counter_file.txt if it does not exist and initialize it with 0.
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    BOOL isDir = YES;
    NSString *path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,file];
    if (![filemng fileExistsAtPath:path isDirectory:&isDir]) {
        [filemng createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    if (![filemng fileExistsAtPath:[NSString stringWithFormat:@"%@/counter_file.txt",path]]) {
        NSString *cnt = [[NSString alloc] initWithFormat:@"0"];
        NSData *data = [cnt dataUsingEncoding:NSUTF8StringEncoding];
        [filemng createFileAtPath:[NSString stringWithFormat:@"%@/counter_file.txt",path] contents:data attributes:nil];
    }
    
    // increase by 1 the counter_file.txt
    int icnt;
    NSString *cnt = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/counter_file.txt",path] encoding:NSUTF8StringEncoding error:NULL];
    icnt = [cnt intValue] +1; //update the value of the counter
    cnt = [NSString stringWithString:[NSString stringWithFormat: @"%d",icnt]];
    [cnt writeToFile:[NSString stringWithFormat:@"%@/counter_file.txt",path] atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
    return path;

}


+ (double *) readTemplate:(NSString *)filename //return pointer to template from filename
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/Templates/%@",documentsDirectory,filename];
    NSString *content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSArray *file = [content componentsSeparatedByString:@"\n"];
    
    double *r = malloc((file.count)*sizeof(double));
    for (int i=0; i<file.count; i++) {
        NSString *str = [file objectAtIndex:i];
        *(r+i) = [str doubleValue];
    }
    
    return r;
}

+ (void) writeImageToDisk:(CGImageRef)image withTitle:(NSString *)title
{
    
    // Create paths to output images
    NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.jpg",title]];
    
    // Write a UIImage to JPEG with minimum compression (best quality)
    // The value 'image' must be a UIImage object
    // The value '1.0' represents image compression quality as value from 0.0 to 1.0
    [UIImageJPEGRepresentation([UIImage imageWithCGImage:image scale:1.0 orientation:3], 1.0) writeToFile:jpgPath atomically:YES];
    
    
//    // Let's check to see if files were successfully written    
//    // Create file manager
//    NSError *error;
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
//    
//    // Point to Document directory
//    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
//    
//    // Write out the contents of home directory to console
//    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);

}




//***********************************************************************************************************************************
//TODO: float vector to double!
+ (void)writeTemplate:(double *)vect withSize:(int *)size withTitle:(NSString *) filename
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/Templates/%@",documentsDirectory,filename];
    
    NSMutableString *content = [NSMutableString stringWithCapacity:size[0]*size[1]*size[2]+3];
    [content appendFormat:@"%d\n",size[0]];
    [content appendFormat:@"%d\n",size[1]];
    [content appendFormat:@"31\n"];
    for (int i = 0; i<size[0]*size[1]*size[2]; i++)
        [content appendFormat:@"%f\n",*(vect + i)];
    
    if([content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:NULL]){
        NSLog(@"Write Template Work!");
    }
}


+ (void)writeImage:(UInt8 *)vect withSize:(int *)size withTitle:(NSString *) filename
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,filename];
    
    
    NSMutableString *content = [NSMutableString stringWithCapacity:size[0]*size[1]*3+2];
    [content appendFormat:@"%d\n",size[0]];
    [content appendFormat:@"%d\n",size[1]];
    
    
    for (int i=0; i<size[0]*size[1]; i++) {
        [content appendFormat:@"%d\n",*(vect +4*i)];
        [content appendFormat:@"%d\n",*(vect +4*i+1)];
        [content appendFormat:@"%d\n",*(vect +4*i+2)];
    }
    
    [content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}


+ (void)write:(double *)vect withSize:(int *)size withTitle:(NSString *) filename
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,filename];
    
    NSMutableString *content = [NSMutableString stringWithCapacity:size[0]*size[1]+2];
    [content appendFormat:@"%d\n",size[0]];
    [content appendFormat:@"%d\n",size[1]];
    for (int x = 0; x<size[1]*size[0]; x++) {
        [content appendFormat:@"%f\n",*(vect +x)];
    }
    
    [content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}



+ (void)writeImages:(UInt8 *)vect withSize:(int *)size withTitle:(NSString *) filename
{
    /* NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
     NSString * path = [NSString stringWithFormat:@"%@/%@",documentsDirectory,filename];*/
    
    NSMutableString *content = [NSMutableString stringWithCapacity:size[0]*size[1]*3+2];
    [content appendFormat:@"%d\n",size[0]];
    [content appendFormat:@"%d\n",size[1]];
    
    
    for (int i=0; i<size[0]*size[1]; i++) {
        [content appendFormat:@"%d\n",*(vect +4*i)];
        [content appendFormat:@"%d\n",*(vect +4*i+1)];
        [content appendFormat:@"%d\n",*(vect +4*i+2)];
    }
    NSError *error;
    if([content writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:&error]){
        NSLog(@"Ok2");
    }
    else{
        NSLog(@"No Ok2: %@",error.localizedDescription);
    }
    
}

+ (void)writeConv:(double *)vect withSize:(int *)size withTitle:(NSString *) filename
{
    
    NSMutableString *content = [NSMutableString stringWithCapacity:size[0]*size[1]+2];
    [content appendFormat:@"%d\n",size[0]];
    [content appendFormat:@"%d\n",size[1]];
    for (int x = 0; x<size[1]*size[0]; x++) {
        [content appendFormat:@"%f\n",*(vect +x)];
        
        
    }
    [content writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}

+ (void)writeConvWithArray:(NSArray *)conv withSize:(int *)size withTitle:(NSString *) filename
{
    NSMutableString *content = [NSMutableString stringWithCapacity:conv.count+2];
    [content appendFormat:@"%d\n",size[0]];
    [content appendFormat:@"%d\n",size[1]];
    for (int x = 0; x<conv.count; x++) {
        ConvolutionPoint * p = [conv objectAtIndex:x];
        [content appendFormat:@"%f\n",p.score];
    }
    [content writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:NULL];
}


@end
