//
//  UIButtonCamera.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 09/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "UIButtonCamera.h"

@implementation UIButtonCamera


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
        [self addObserver:self forKeyPath:@"highlighted" options:NSKeyValueObservingOptionNew context:NULL];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.highlighted == YES)
    {
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    }
    else
    {
//        self.layer.cornerRadius = 10;
//        self.layer.borderColor = [[UIColor blackColor] CGColor];
//        self.layer.borderWidth = 1;
        self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
        [self setTitle:@"Ramon" forState:UIControlStateNormal];
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"highlighted"];
}


@end
