//
//  InfiniteLoopView.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfiniteLoopDataSoruce <NSObject>

- (UIView *) viewForIndex:(int)index;
- (int) numberOfViews;

@end

@protocol InfiniteLoopDelegate <NSObject>

- (void) changedToView:(UIView *)currentView withIndex:(int)index;

@end

@interface InfiniteLoopView : UIView <UIScrollViewDelegate>

@property (nonatomic, strong) id <InfiniteLoopDataSoruce> dataSource;
@property (nonatomic, strong) id <InfiniteLoopDelegate> delegate;


@end
