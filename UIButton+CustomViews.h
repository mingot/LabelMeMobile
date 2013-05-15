//
//  UIButton+CustomViews.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 14/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AYUIButton.h"

@interface UIButton (CustomViews)


//button with style for the navigation bar
+ (AYUIButton *) buttonBarWithTitle:(NSString *)title target:(id)target action:(SEL)selector;

//custom plus button for bar 
+ (AYUIButton *) plusBarButtonWithTarget:(id)target action:(SEL) selector;

//it returns the same button with the alpha reduced in highlighted mode
- (void) highlightButton;

@end
