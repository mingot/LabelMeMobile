//
//  UITextField+CorrectOrientation.h
//  LabelMe
//
//  Created by Dolores on 02/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Box.h"

@interface UITextField (CorrectOrientation)

-(void)setCorrectOrientationForBox:(Box *)box subviewFrame:(CGRect)viewFrame andViewSize:(CGSize)viewSize andScale:(float)scale;

@end
