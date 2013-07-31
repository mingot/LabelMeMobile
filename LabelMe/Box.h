//
//  Box.h
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>

@interface Box : NSObject <NSCoding>
{
    CGPoint upperLeft;
    CGPoint lowerRigth;
}

@property (strong, nonatomic) NSString *label;
@property (strong, nonatomic) NSString *date;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) NSDate *downloadDate;
@property float lineWidth;
@property CGSize imageSize;
@property BOOL sent;


- (id) initWithPoints:(CGPoint)upper :(CGPoint)lower;
- (void) setBounds:(CGRect)rect;
- (int) setUpperLeft:(CGPoint)point;
- (int) setLowerRight:(CGPoint)point;
- (CGPoint) upperLeft;
- (CGPoint) lowerRight;
- (void) updatePoints:(CGPoint)start :(CGPoint) end;
- (CGPoint) bounds;
- (NSString *) generateDateString;

//returns the CGRect of the Box
- (CGRect) getRectangleForBox;

//adapt box to image size
- (void) setBoxDimensionsForImageSize:(CGSize) size;
- (void) setLimitsForImageSize:(CGSize) size;

@end
