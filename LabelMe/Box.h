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

@property (strong, nonatomic) NSString *label;
@property (strong, nonatomic) NSString *date;
@property (strong, nonatomic) UIColor *color;
@property (strong, nonatomic) NSDate *downloadDate;
@property float lineWidth;
@property CGSize imageSize;
@property CGPoint upperLeft;
@property CGPoint lowerRight;
@property BOOL sent;

@property int cornerMoving;

- (id) initWithUpperLeft:(CGPoint)upper lowerRight:(CGPoint)lower forImageSize:(CGSize)imageSize;



- (void) resizeUpperLeftToPoint:(CGPoint)upperLeft;
- (void) resizeLowerRightToPoint:(CGPoint)lowerRight;
//- (void) resizeForCorner:(int)corner toPoint:(CGPoint)point;

//- (void) updatePoints:(CGPoint)start :(CGPoint) end;
- (void) moveFromPoint:(CGPoint)start toPoint:(CGPoint)end;

//returns the CGRect of the Box
- (CGRect) getRectangleForBox;

//adapt box to image size
- (void) setBoxDimensionsForImageSize:(CGSize) size;

@end
