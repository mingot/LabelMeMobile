//
//  UIButton+CustomViews.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 14/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "UIButton+CustomViews.h"



@implementation UIButton (CustomViews)


+ (AYUIButton *) buttonBarWithTitle:(NSString *)title target:(id)target action:(SEL)selector
{
    AYUIButton *button = [AYUIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor colorWithWhite:0.4 alpha:0.6] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithWhite:0.4 alpha:0.3] forState:UIControlStateHighlighted];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:10.0];
    [button setFrame:CGRectMake(0, 0, 51,28)];
    
    return button;
}

+ (AYUIButton *) plusBarButtonWithTarget:(id)target action:(SEL) selector
{
    AYUIButton *button = [AYUIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor colorWithWhite:0.4 alpha:0.6] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor colorWithWhite:0.4 alpha:0.3] forState:UIControlStateHighlighted];
    [button setTitle:@"+" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [button setFrame:CGRectMake(0, 0, 30,28)];
    
    return button;
}




@end
