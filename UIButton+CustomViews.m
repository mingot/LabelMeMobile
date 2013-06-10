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
    button.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [button setFrame:CGRectMake(0, 0, 61,28)];
    
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





- (void) highlightButton
{
    AYUIButton *button = (AYUIButton *) self;
    [button setBackgroundColor:self.backgroundColor forState:UIControlStateNormal];
    CGFloat red, blue, green, alpha;
    [self.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    [button setBackgroundColor:[UIColor colorWithRed:red green:green blue:blue alpha:alpha/2.0] forState:UIControlStateHighlighted];
    
    button.layer.shadowColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:1].CGColor;
    button.layer.shadowOpacity = 1;
    button.layer.shadowRadius = 2;
    button.layer.shadowOffset = CGSizeMake(0,1);
    button.layer.cornerRadius = 5;
}

@end
