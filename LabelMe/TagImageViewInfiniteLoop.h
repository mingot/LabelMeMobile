//
//  TagImageViewInfiniteLoop.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 04/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "TagImageView.h"

@protocol TagImageViewInfiniteLoopDataSource <NSObject>

- (UIView *) viewForIndex:(int)index;
- (int) numberOfViews;

@end

@protocol TagImageViewInfiniteLoopDelegate <NSObject>

// Informed the delegate which is the view and index currently displaying
- (void) changedToView:(UIView *)currentView withIndex:(int)index;

@end


@interface TagImageViewInfiniteLoop : TagImageView

@property (nonatomic, weak) IBOutlet id <TagImageViewInfiniteLoopDataSource> dataSource;
@property (nonatomic, weak) IBOutlet id <TagImageViewInfiniteLoopDelegate> delegate;

@end
