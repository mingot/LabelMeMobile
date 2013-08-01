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
@property CGSize imageSize;
@property CGPoint upperLeft;
@property CGPoint lowerRight;
@property BOOL sent;
@property CGFloat lineWidth;




- (id) initWithUpperLeft:(CGPoint)upper lowerRight:(CGPoint)lower forImageSize:(CGSize)imageSize;

// Returns the position of the touch with respect the box.
- (int) touchAtPoint:(CGPoint)point;

// Box Resize
// Indicate the touch point that initiates the resizing. This method fixes
// the |_cornerResizing| that stores the corner being used to resize
- (void) resizeBeginAtPoint:(CGPoint) point;
// Resizes from the |_cornerResizing| to the point
- (void) resizeToPoint:(CGPoint) point;


// Box Move
// Used when initiating a move to fix the origin point of the move
- (void) moveBeginAtPoint:(CGPoint) point;
// Moves from the previous fixed to the new one
- (void) moveToPoint:(CGPoint)end;

// When needed returns a CGRect from the box
- (CGRect) getRectangleForBox;

// When loading, adjusts the box size to the iamgeSize provided. Used when
// rotating the phone that the boxes need to reajust to the new image size.
- (void) setBoxDimensionsForImageSize:(CGSize) size;




@end
