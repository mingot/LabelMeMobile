//
//  BoxTouchHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 30/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "BoxTouchHandler.h"

@interface BoxTouchHandler()
{
    BOOL _move;
    BOOL _size;
    int _corner;
    Box* _selectedBox;
    NSMutableArray* _boxes;
}


@end


@implementation BoxTouchHandler

- (void) touchesBeganAtPoint:(CGPoint) point
{
}

- (void) touchesMovedAtPoint:(CGPoint) point
{
}

- (void) touchesEnded
{
}

- (Box *) selectedBox;
{
    return _selectedBox;
}

- (void) setBoxes:(NSMutableArray *)boxes
{
    _boxes = boxes;
}

@end
