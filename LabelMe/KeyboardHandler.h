//
//  KeyboardHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 01/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//



// Moves the given view up if it was hidden by the keyboard


#import <Foundation/Foundation.h>

@interface KeyboardHandler : NSObject

-(id) initWithView:(UIView *)movingView;

@end
