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

// Provides Image and TagView with zooming capabilities

@interface TagImageView : UIView <UIScrollViewDelegate>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) TagView *tagView;

// Return to the initial state of zoom
- (void) resetZoomView;

- (UIImage *) takeThumbnailImage;

// Returns the visible rectabgle when zooming
// Needed to create a new box when zoom is in
- (CGRect) getVisibleRect;

// Reajust subviews after rotation
- (void) reloadForRotation;

@end
