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

-(void)fitForBox:(Box *)box onTagViewFrame:(CGRect)viewFrame andScale:(float)scale;

@end
