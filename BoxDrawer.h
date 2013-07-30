//
//  BoxDrawer.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 30/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Box.h"

@interface BoxDrawer : NSObject //<BoxDrawDelegate>

- (void) drawBox:(Box *)box forContext:(CGContextRef)context;
- (void) setSelectedBox:(Box *) box;

@end
