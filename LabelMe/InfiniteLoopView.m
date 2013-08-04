//
//  InfiniteLoopView.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "InfiniteLoopView.h"

#define module(a, b) (a >= 0) ? (a)%b : ((a)%(b) + b)
#define kViewTag 10

@interface InfiniteLoopView()
{
    UIScrollView *_scrollView;
    UIView *_pageOneView;
    UIView *_pageTwoView;
    UIView *_pageThreeView;
    int _currIndex;
    int _prevIndex;
    int _nextIndex;
}

@end


@implementation InfiniteLoopView

- (void) initializeAtIndex:(int) initialIndex;
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    _scrollView.pagingEnabled = YES;
    _scrollView.contentSize = CGSizeMake(960, 460);
    [_scrollView scrollRectToVisible:CGRectMake(320,0,320,460) animated:NO];
    _scrollView.delegate = self;
    
    [self addSubview:_scrollView];
    
    // create placeholders for each of our documents
    _pageOneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    _pageTwoView = [[UIView alloc] initWithFrame:CGRectMake(320, 0, 320, 460)];
    _pageThreeView = [[UIView alloc] initWithFrame:CGRectMake(640, 0, 320, 460)];
    
    _pageOneView.backgroundColor = [UIColor blackColor];
    _pageTwoView.backgroundColor = [UIColor blackColor];
    _pageThreeView.backgroundColor = [UIColor blackColor];
    
    [_scrollView addSubview:_pageOneView];
    [_scrollView addSubview:_pageTwoView];
    [_scrollView addSubview:_pageThreeView];
    
    // load all three pages into our scroll view
    int total = [self.dataSource numberOfViews];
    NSLog(@"Requested index: %d, %d, %d", module(initialIndex - 1,total), module(initialIndex,total), module(initialIndex + 1,total));
    [self loadPageWithId:module(initialIndex - 1,total) onPage:0];
    [self loadPageWithId:module(initialIndex, total) onPage:1];
    [self loadPageWithId:module(initialIndex + 1, total) onPage:2];
}

#pragma mark - 
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{

    int total = [self.dataSource numberOfViews];
    int previousIndex = _currIndex;

    if(_scrollView.contentOffset.x > _scrollView.frame.size.width) {

        [self loadPageWithId:_currIndex onPage:0];
        
        _currIndex = (_currIndex >= total - 1) ? 0 : _currIndex + 1;
        [self loadPageWithId:_currIndex onPage:1];
        
        _nextIndex = (_currIndex >= total - 1) ? 0 : _currIndex + 1;
        [self loadPageWithId:_nextIndex onPage:2];
    }
    if(_scrollView.contentOffset.x < _scrollView.frame.size.width) {

        [self loadPageWithId:_currIndex onPage:2];
        
        _currIndex = (_currIndex == 0) ? total - 1 : _currIndex - 1;
        [self loadPageWithId:_currIndex onPage:1];
        
        _prevIndex = (_currIndex == 0) ? total - 1 : _currIndex - 1;
        [self loadPageWithId:_prevIndex onPage:0];
    }
    
    // Reset offset back to middle page
    [_scrollView scrollRectToVisible:CGRectMake(320,0,320,460) animated:NO];
    
    //inform the delegate of the change
    [self.delegate changedFromindex:previousIndex toIndex:_currIndex];

}


#pragma mark -
#pragma mark Public Methods

- (void) disableScrolling:(BOOL) disable
{    
    _scrollView.scrollEnabled = !disable;
}


#pragma mark -
#pragma mark Private Methods

- (void)loadPageWithId:(int)index onPage:(int)page
{
	UIView *view = [self.dataSource viewForIndex:index];
    view.frame = _pageOneView.frame;
    view.tag = kViewTag;
    
    
    // load data for page
    switch (page) {
		case 0:
        {
            UIView *viewToRemove = [_pageOneView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageOneView addSubview:view];
			break;
        }
		case 1:
        {
            UIView *viewToRemove = [_pageTwoView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageTwoView addSubview:view];
			break;
        }
		case 2:
        {
            UIView *viewToRemove = [_pageThreeView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageThreeView addSubview:view];
			break;
        }
	}
    
    [self setNeedsDisplay];
}

@end





