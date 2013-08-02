//
//  TagImageView.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 31/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TagView.h"
#import "Box.h"

@interface TagImageView : UIView <UIScrollViewDelegate>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) TagView *tagView;

- (void) addNewBox;
- (void) removeSelectedBox;

@end
