//
//  BoxDrawer.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 30/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "BoxDrawer.h"

@interface BoxDrawer()
{
    Box* _selectedBox;
}

@end


@implementation BoxDrawer

- (void) drawBox:(Box *)box forContext:(CGContextRef)context
{
    BOOL showCorners;
    CGFloat alpha;
    
    if(_selectedBox == nil){
        alpha = 1;
        showCorners = false;
        
    }else if(_selectedBox == box){
        alpha = 1;
        showCorners = true;
        
    }else{
        alpha = 0.3;
        showCorners = false;
    }
    
    CGPoint upperRight = CGPointMake([box lowerRight].x, [box upperLeft].y);
    CGPoint lowerLeft = CGPointMake([box upperLeft].x, [box lowerRight].y);
    CGFloat LINEWIDTH = box->LINEWIDTH;
    
    // DRAW RECT
    CGContextSetLineWidth(context, LINEWIDTH);
    CGRect rect = CGRectMake([box upperLeft].x, [box upperLeft].y, [box lowerRight].x-[box upperLeft].x, [box lowerRight].y-[box upperLeft].y);
    const CGFloat *components = CGColorGetComponents(box.color.CGColor);
    CGContextSetRGBStrokeColor(context, components[0] ,components[1],components[2], alpha);
    CGContextStrokeRect(context, rect);

    // DRAW CORNERS
    if(showCorners){
        CGContextStrokeEllipseInRect(context, CGRectMake([box upperLeft].x-LINEWIDTH, [box upperLeft].y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake([box lowerRight].x-LINEWIDTH, [box lowerRight].y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-LINEWIDTH, upperRight.y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-LINEWIDTH, lowerLeft.y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextSetRGBStrokeColor(context, 255, 255, 255, 1);
        CGContextSetLineWidth(context, 1);
        CGContextStrokeEllipseInRect(context, CGRectMake([box upperLeft].x-1.5*LINEWIDTH, [box upperLeft].y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake([box lowerRight].x-1.5*LINEWIDTH, [box lowerRight].y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-1.5*LINEWIDTH, upperRight.y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-1.5*LINEWIDTH, lowerLeft.y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
    }

}

- (void) setSelectedBox:(Box *)box
{
    _selectedBox = box;
}

@end
