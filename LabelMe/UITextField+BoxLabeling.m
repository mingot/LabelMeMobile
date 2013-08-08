//
//  UITextField+CorrectOrientation.m
//  LabelMe
//
//  Created by Dolores on 02/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "UITextField+BoxLabeling.h"

@implementation UITextField (BoxLabeling)


- (void) initialSetup
{
    [self setBorderStyle:UITextBorderStyleNone];
    [self setKeyboardAppearance:UIKeyboardAppearanceAlert];
    self.placeholder = @"Enter Label:";
    self.textAlignment = UITextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
    self.hidden = YES;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

-(void)fitForBox:(Box *)box;
{
    CGRect tagViewFrame = [self superview].frame;
    float topDif = box.upperLeft.y;
    float topWidthDif = tagViewFrame.size.width - box.upperLeft.x;
    float topHeightDif = tagViewFrame.size.height - box.upperLeft.y;
    float bottomDif = tagViewFrame.size.height - box.lowerRight.y;
    float rightDif = tagViewFrame.size.width - box.lowerRight.x;
    float leftDif = box.upperLeft.x;
    
    NSString *imageName;
    CGFloat x, y;
    int tag;
    
    if (topDif >= self.frame.size.height && topWidthDif >= self.frame.size.width){

        //top
        imageName = @"globo.png";
        x = box.upperLeft.x;
        y = box.upperLeft.y - self.frame.size.height;
        tag = 0;
        
    }else if (rightDif >= self.frame.size.width && topHeightDif >= self.frame.size.height){
        
        //right
        imageName = @"globo2.png";
        x = box.lowerRight.x;
        y = box.upperLeft.y;
        tag = 2;
        
    }else if(bottomDif >= self.frame.size.height && topWidthDif >= self.frame.size.width){
        
        //bottom
        imageName = @"globo2.png";
        x = box.upperLeft.x;
        y = box.lowerRight.y;
        tag = 1;
        
    }else if (leftDif >= self.frame.size.width && topHeightDif >= self.frame.size.height){
        
        //left
        imageName = @"globo3.png";
        x = box.upperLeft.x - self.frame.size.width;
        y = box.upperLeft.y;
        tag = 3;

    }else{
        
        // OP 5
        imageName = @"globo2.png";
        x = box.upperLeft.x;
        y = box.upperLeft.y;
        tag = 4;
    }
    
    [self setBackground:[[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23)]];
    self.frame = CGRectMake(x, y, self.frame.size.width, self.frame.size.height);
    self.tag = tag;
}

@end
