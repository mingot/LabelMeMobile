//
//  DetectView.m
//  ImageG
//
//  Created by Dolores Blanco Almazán on 12/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetectView.h"
#import "ConvolutionHelper.h"
#import "math.h"


static inline double min(double x, double y) { return (x <= y ? x : y); }
static inline double max(double x, double y) { return (x <= y ? y : x); }


@implementation DetectView

@synthesize corners = _corners;


- (void)drawRect:(CGRect)rect
{

    if (self.corners.count!=0){
        CGContextRef context = UIGraphicsGetCurrentContext();
        BoundingBox *p;
        CGFloat x,y,w,h;
        
        for (int i=0; i<self.corners.count; i++){
        
            //convert the point from the device system of reference to the prevLayer system of reference
            p = [self convertBoundingBoxForDetectView:[self.corners objectAtIndex:i]];
            
            //set the rectangle within the current boundaries 
            x = max(0,p.xmin);
            y = max(0,p.ymin);
            w = min(self.frame.size.width,p.xmax) - x;
            h = min(self.frame.size.height,p.ymax) - y;
            
            
            CGRect box = CGRectMake(x, y, w, h);
            if(i==0){
                CGContextSetLineWidth(context, 4);
                CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
                CGContextStrokeRect(context, box);
                
                // for the rest of boxes
                CGContextSetLineWidth(context, 1);
                CGContextSetStrokeColorWithColor(context, [UIColor purpleColor].CGColor);
                
            }else CGContextStrokeRect(context, box);
        }
    }
}


- (BoundingBox *) convertBoundingBoxForDetectView:(BoundingBox *) cp
{
    BoundingBox *newCP = [[BoundingBox alloc] init];
    
    CGPoint upperLeft = [self.prevLayer pointForCaptureDevicePointOfInterest:CGPointMake(cp.ymin, 1 - cp.xmin)];
    CGPoint lowerRight = [self.prevLayer pointForCaptureDevicePointOfInterest:CGPointMake(cp.ymax, 1 - cp.xmax)];
    
    newCP.xmin = upperLeft.x;
    newCP.ymin = upperLeft.y;
    newCP.xmax = lowerRight.x;
    newCP.ymax = lowerRight.y;
    
    return newCP;
}


- (void)reset
{
    self.corners = nil;
}

@end
