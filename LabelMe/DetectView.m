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


@implementation DetectView

@synthesize corners = _corners;


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    
    // correction of the aspect fill of prevLayer
    // FIXME: hardcoded numbers
    CGFloat offset, scale;
    offset = self.frame.size.width*0.08/2.0;
    scale = 1.3;
    
    // Drawing code
    if (self.corners.count!=0)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        ConvolutionPoint *p;
        CGFloat x,y,w,h;
        
        for (int i=0; i<self.corners.count; i++) 
        {
            p = [self.corners objectAtIndex:i];
            
            x = p.xmin * self.frame.size.width - offset;
            y = p.ymin * self.frame.size.height;
            w = (p.xmax - p.xmin)*self.frame.size.width*scale;
            h = (p.ymax - p.ymin)*self.frame.size.height;
            
            
            CGRect box = CGRectMake(x, y, w, h);
            if(i==0)
            {
                CGContextSetLineWidth(context, 4);
                CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
                CGContextStrokeRect(context, box);
                
                // for the rest of boxes
                CGContextSetLineWidth(context, 1);
                CGContextSetStrokeColorWithColor(context, [UIColor purpleColor].CGColor);
                
            }else CGContextStrokeRect(context, box );
        }
    }
}

- (void)reset
{
    self.corners = nil;
}

@end
