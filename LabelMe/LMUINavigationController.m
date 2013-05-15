//
//  LMUINavigationController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 14/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "LMUINavigationController.h"

@implementation LMUINavigationController


+ (UIImage*)drawImageWithSolidColor:(UIColor*) color
{
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *imagePath;
//    imagePath = [[paths lastObject] stringByAppendingPathComponent:@"NavImage.png"];
//    if([fileManager fileExistsAtPath:imagePath]){
//        return  [UIImage imageWithData:[NSData dataWithContentsOfFile:imagePath]];
//    }
    UIGraphicsBeginImageContext(CGSizeMake(320, 40));
    [color setFill];
    UIRectFill(CGRectMake(0, 0, 320, 40));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
//    NSData *data = UIImagePNGRepresentation(image);
//    [data writeToFile:imagePath atomically:YES];
    return image;
}

@end
