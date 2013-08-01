//
//  TagImageView.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 31/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagView.h"

@interface TagImageView : UIView <UIScrollViewDelegate, TagViewDelegate>

@property (nonatomic, strong) NSArray *boxes;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) TagView *tagView;

- (id)initWithFrame:(CGRect)frame WithBoxes:(NSArray *)boxes forImage:(UIImage *) image;

@end
