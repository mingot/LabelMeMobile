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

// Inform the delegate about the change of views in the scroll 
- (void) changedFromindex:(int) previousIndex toIndex:(int)currentIndex;

@end

@interface InfiniteLoopView : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet id <InfiniteLoopDataSoruce> dataSource;
@property (nonatomic, weak) IBOutlet id <InfiniteLoopDelegate> delegate;


// Needs to be called after the delegate and data source have been hooked
// |ViewDidLoad| or subsequent loading views calls are usually a good place for doing so
- (void) initializeAtIndex:(int) initialIndex;

// Needed when a box is selected to diable scrolling
- (void) disableScrolling:(BOOL) disable;

@end