//
//  UITextField+CorrectOrientation.h
//  LabelMe
//
//  Created by Dolores on 02/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (CorrectOrientation)

-(void)setCorrectOrientationWithCorners:(CGPoint)upperLeft : (CGPoint)lowerRight subviewFrame:(CGRect)viewFrame andViewSize:(CGSize)viewSize andScale:(float)scale;

@end
