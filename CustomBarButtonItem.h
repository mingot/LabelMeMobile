//
//  CustomBarButtonItem.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 30/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CustomBarButtonItem : UIBarButtonItem 

- (id) initWithImage:(UIImage *)image title:(NSString *)title target:(id)target action:(SEL)action;

@end


@interface UIBarButtonItem (CustomBarButtonItem)

+ (UIBarButtonItem *) barButtonItemWithImage:(UIImage *)image title:(NSString *)title target:(id)target action:(SEL)action;

@end
