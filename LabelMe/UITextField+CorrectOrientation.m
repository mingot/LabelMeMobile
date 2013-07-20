//
//  UITextField+CorrectOrientation.m
//  LabelMe
//
//  Created by Dolores on 02/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "UITextField+CorrectOrientation.h"

@implementation UITextField (CorrectOrientation)

-(void)setCorrectOrientationForBox:(Box *)box subviewFrame:(CGRect)viewFrame andViewSize:(CGSize)viewSize andScale:(float)scale
{
    //viewframe = tagview.frame
    //viewsize = scrollview.frame.size
    //scael = scrollview.zoomscale
    float topDif = box.upperLeft.y + viewFrame.origin.y;
    float bottomDif = viewSize.height - box.lowerRight.y - viewFrame.origin.y;
    float rightDif = viewSize.width - box.lowerRight.x - viewFrame.origin.x;
    float leftDif = box.upperLeft.x + viewFrame.origin.x;
    
    if ((topDif >= self.frame.size.height) && (viewFrame.size.width - box.upperLeft.x >= self.frame.size.width) ){

        // op1 115x87; 57x43
        [self setBackground:[[UIImage imageNamed:@"globo.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )]];
        self.frame = CGRectMake((box.upperLeft.x + viewFrame.origin.x)*scale,
                                (box.upperLeft.y + viewFrame.origin.y)*scale - self.frame.size.height,
                                self.frame.size.width,
                                self.frame.size.height);
        self.tag = 0;
        
    }else if ((rightDif >= self.frame.size.width) && (viewFrame.size.height - box.upperLeft.y >= self.frame.size.height) ){
        
        // op 3
        [self setBackground:[[UIImage imageNamed:@"globo2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )]];
        self.frame = CGRectMake((box.lowerRight.x +viewFrame.origin.x)*scale,
                                (box.upperLeft.y +viewFrame.origin.y)*scale,
                                self.frame.size.width,
                                self.frame.size.height);
        self.tag = 2;
        
    }else if((bottomDif >= self.frame.size.height) && (viewFrame.size.width - box.upperLeft.x >= self.frame.size.width)){
        
        // op2
        [self setBackground:[[UIImage imageNamed:@"globo2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )]];
        self.frame = CGRectMake((box.upperLeft.x+viewFrame.origin.x)*scale,
                                (box.lowerRight.y+viewFrame.origin.y)*scale,
                                self.frame.size.width,
                                self.frame.size.height);
        self.tag = 1;
     
        
    }else if ((leftDif >= self.frame.size.width) && (viewFrame.size.height - box.upperLeft.y >= self.frame.size.height)){
        
        // op 4
        [self setBackground:[[UIImage imageNamed:@"globo3.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23)]];
        self.frame = CGRectMake((box.upperLeft.x +viewFrame.origin.x)*scale -self.frame.size.width,
                                (box.upperLeft.y +viewFrame.origin.y)*scale,
                                self.frame.size.width,
                                self.frame.size.height);
        self.tag = 3;

    }else{
        
        // OP 5
        [self setBackground:[[UIImage imageNamed:@"globo2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )]];
        self.frame = CGRectMake((box.upperLeft.x+viewFrame.origin.x)*scale,
                                (box.upperLeft.y +viewFrame.origin.y)*scale,
                                self.frame.size.width,
                                self.frame.size.height);
        self.tag = 4;
    }
}

@end
