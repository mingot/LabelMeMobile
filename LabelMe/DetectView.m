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



- (void)drawRect:(CGRect)rect
{
    
    //for each group of corners generated (by nmsarray)
    int j=0;
    for(NSArray *corners in self.cornersArray){
        
        
        if (corners.count==0) continue; //skip if no bb for this class
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        BoundingBox *p;
        CGFloat x,y,w,h; //xbox: x for the box position
    
    
        for (int i=0; i<corners.count; i++){
        
            //convert the point from the device system of reference to the prevLayer system of reference
            p = [self convertBoundingBoxForDetectView:[corners objectAtIndex:i]];
            
            //set the rectangle within the current boundaries 
            x = max(0,p.xmin);
            y = max(0,p.ymin);
            w = min(self.frame.size.width,p.xmax) - x;
            h = min(self.frame.size.height,p.ymax) - y;
        
            CGRect box = CGRectMake(x, y, w, h);
            
            CGContextSetLineWidth(context, 4);
            UIColor *color = [self.colorsDictionary objectForKey:p.targetClass];
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            j++;
            CGContextStrokeRect(context, box);
            
            //text drawing
            CGContextSetFillColorWithColor(context,color.CGColor);
            CGFloat textBoxHeight = 20;
            
            //handle distinct orientations
            if(self.frontCamera){
                x = x + w;
                w = abs(w);
            }
            
            CGRect textBox = CGRectMake(x - 2, y - 20 - 2, w/2.0, textBoxHeight);
            CGContextFillRect(context, textBox);
            CGContextSetFillColorWithColor(context,[UIColor blackColor].CGColor);
            [[NSString stringWithFormat:@" %@", p.targetClass] drawInRect:textBox withFont:[UIFont systemFontOfSize:15]];
        }
        
    }
}


- (BoundingBox *) convertBoundingBoxForDetectView:(BoundingBox *) cp
{
    BoundingBox *newCP = [[BoundingBox alloc] initWithBoundingBox:cp];
    
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
    self.cornersArray = nil;
}

@end
