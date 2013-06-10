//
//  UIImage+Border.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 07/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "UIImage+Border.h"

@implementation UIImage (Border)


- (UIImage *) addBorderForViewFrame:(CGRect )frame;
{
    CGImageRef bgimage = self.CGImage;
	float width = CGImageGetWidth(bgimage);
	float height = CGImageGetHeight(bgimage);
    // Create a temporary texture data buffer
	void *data = malloc(width * height * 4);
    
	// Draw image to buffer
	CGContextRef ctx = CGBitmapContextCreate(data,
                                             width,
                                             height,
                                             8,
                                             width * 4,
                                             CGImageGetColorSpace(self.CGImage),
                                             kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), bgimage);
	//Set the stroke (pen) color
	CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:(160/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0].CGColor);
    
	//Set the width of the pen mark
	CGFloat borderWidth = 6;
	CGContextSetLineWidth(ctx, borderWidth);
    
	//Start at 0,0 and draw a square
    CGContextMoveToPoint(ctx, borderWidth/2, borderWidth/2);
	CGContextAddLineToPoint(ctx, frame.size.width*0.4125-borderWidth/2, borderWidth/2);
	CGContextAddLineToPoint(ctx, frame.size.width*0.4125-borderWidth/2, frame.size.width*0.4125-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2,frame.size.width*0.4125-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2, 0);
	//Draw it
	CGContextStrokePath(ctx);
    
    // write it to a new image
	CGImageRef cgimage = CGBitmapContextCreateImage(ctx);
	UIImage *newImage = [UIImage imageWithCGImage:cgimage];
	CFRelease(cgimage);
	CGContextRelease(ctx);
    free(data);
    
	return newImage;
}

@end
