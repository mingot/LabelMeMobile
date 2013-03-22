//
//  UITextField+CorrectOrientation.m
//  LabelMe
//
//  Created by Dolores on 02/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "UITextField+CorrectOrientation.h"

@implementation UITextField (CorrectOrientation)

-(void)setCorrectOrientationWithCorners:(CGPoint)upperLeft : (CGPoint)lowerRight subviewFrame:(CGRect)viewFrame andViewSize:(CGSize)viewSize andScale:(float)scale{
    
    float topDif = upperLeft.y + viewFrame.origin.y;
    float bottomDif = viewSize.height - lowerRight.y - viewFrame.origin.y;
    float rightDif = viewSize.width - lowerRight.x - viewFrame.origin.x;
    float leftDif = upperLeft.x + viewFrame.origin.x;
    if ((topDif >= self.frame.size.height) && (viewFrame.size.width - upperLeft.x >= self.frame.size.width) ){

        // op1 115x87; 57x43

            [self setBackground:[[UIImage imageNamed:@"globo.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ] ];
        self.frame = CGRectMake((upperLeft.x + viewFrame.origin.x)*scale,(upperLeft.y+viewFrame.origin.y)*scale - self.frame.size.height , self.frame.size.width, self.frame.size.height);

        self.tag = 0;
        

    }
    else if ((rightDif >= self.frame.size.width) && (viewFrame.size.height - upperLeft.y >= self.frame.size.height) ){
        // op 3
        self.frame = CGRectMake((lowerRight.x +viewFrame.origin.x)*scale,(upperLeft.y +viewFrame.origin.y)*scale, self.frame.size.width, self.frame.size.height);


        [self setBackground:[[UIImage imageNamed:@"globo2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ] ];

        self.tag = 2;

        
        
    }
    else if((bottomDif >= self.frame.size.height) && (viewFrame.size.width - upperLeft.x >= self.frame.size.width)){
        // op2

        [self setBackground:[[UIImage imageNamed:@"globo2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ] ];
        
            self.frame = CGRectMake((upperLeft.x+viewFrame.origin.x)*scale ,(lowerRight.y+viewFrame.origin.y)*scale, self.frame.size.width, self.frame.size.height);
        self.tag = 1;

        
    }
    
    else if ((leftDif >= self.frame.size.width) && (viewFrame.size.height - upperLeft.y >= self.frame.size.height)){
        // op 4

        [self setBackground:[[UIImage imageNamed:@"globo3.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ] ];
            self.frame = CGRectMake((upperLeft.x +viewFrame.origin.x)*scale -self.frame.size.width,(upperLeft.y +viewFrame.origin.y)*scale, self.frame.size.width, self.frame.size.height);

        self.tag = 3;


    }
    else{
         // OP 5
        [self setBackground:[[UIImage imageNamed:@"globo2.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(21, 23, 21 , 23 )  ] ];
        self.frame = CGRectMake((upperLeft.x+viewFrame.origin.x)*scale ,(upperLeft.y +viewFrame.origin.y)*scale, self.frame.size.width, self.frame.size.height);
        self.tag = 4;


    }
    
    
    
}

@end
