//
//  UITextField+CorrectOrientation.h
//  LabelMe
//
//  Created by Dolores on 02/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Box.h"

@interface UITextField (BoxLabeling)

- (void) initialSetup;

- (void) fitForBox:(Box *)box;

@end
