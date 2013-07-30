//
//  BoxTouchHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 30/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Box.h"
#import "TagView.h"

@interface BoxTouchHandler : NSObject //<BoxTouchHandleDelegate>

- (void) touchesBeganAtPoint:(CGPoint) point;
- (void) touchesMovedAtPoint:(CGPoint) point;
- (void) touchesEnded;
- (Box *) selectedBox;
- (void) setBoxes:(NSMutableArray *)boxes;

@end
