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

    UIGraphicsBeginImageContext(CGSizeMake(320, 40));
    [color setFill];
    UIRectFill(CGRectMake(0, 0, 320, 40));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
