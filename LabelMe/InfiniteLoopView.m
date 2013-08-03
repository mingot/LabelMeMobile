//
//  InfiniteLoopView.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "InfiniteLoopView.h"

#define module(a, b) (a >= 0) ? (a % b) : ((a % b) + b)
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

- (void) initialize
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    _scrollView.delegate = self;
    
    // create placeholders for each of our documents
    _pageOneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _pageTwoView = [[UIView alloc] initWithFrame:CGRectMake(320, 0, 320, 44)];
    _pageThreeView = [[UIView alloc] initWithFrame:CGRectMake(640, 0, 320, 44)];
    
    
    // load all three pages into our scroll view
    int initialIndex = 0;
    int total = [self.dataSource numberOfViews];
    [self loadPageWithId:module(initialIndex - 1,total) onPage:0];
    [self loadPageWithId:module(initialIndex, total) onPage:1];
    [self loadPageWithId:module(initialIndex + 1, total) onPage:2];
    
    NSLog(@"total: %d", total);
    NSLog(@"Loading pages: %d, %d, %d",module(initialIndex - 1,total),module(initialIndex,total),module(initialIndex + 1,total));
    
    [_scrollView addSubview:_pageOneView];
    [_scrollView addSubview:_pageTwoView];
    [_scrollView addSubview:_pageThreeView];
    
    // adjust content size for three pages of data and reposition to center page
    _scrollView.contentSize = CGSizeMake(960, 416);
    [_scrollView scrollRectToVisible:CGRectMake(320,0,320,416) animated:NO];
}


- (id)initWithFrame:(CGRect)frame withInitialIndex:(int) initialIndex
{
    if (self = [super initWithFrame:frame]) [self initialize];
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) [self initialize];
    return self;
}


#pragma mark - 
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
	// All data for the documents are stored in an array (documentTitles).
	// We keep track of the index that we are scrolling to so that we
	// know what data to load for each page.
	if(_scrollView.contentOffset.x > _scrollView.frame.size.width) {
		// We are moving forward. Load the current doc data on the first page.
		[self loadPageWithId:_currIndex onPage:0];
		// Add one to the currentIndex or reset to 0 if we have reached the end.
		_currIndex = (_currIndex >= [self.dataSource numberOfViews]-1) ? 0 : _currIndex + 1;
		[self loadPageWithId:_currIndex onPage:1];
		// Load content on the last page. This is either from the next item in the array
		// or the first if we have reached the end.
		_nextIndex = (_currIndex >= [self.dataSource numberOfViews]-1) ? 0 : _currIndex + 1;
		[self loadPageWithId:_nextIndex onPage:2];
	}
	if(_scrollView.contentOffset.x < _scrollView.frame.size.width) {
		// We are moving backward. Load the current doc data on the last page.
		[self loadPageWithId:_currIndex onPage:2];
		// Subtract one from the currentIndex or go to the end if we have reached the beginning.
		_currIndex = (_currIndex == 0) ? [self.dataSource numberOfViews]-1 : _currIndex - 1;
		[self loadPageWithId:_currIndex onPage:1];
		// Load content on the first page. This is either from the prev item in the array
		// or the last if we have reached the beginning.
		_prevIndex = (_currIndex == 0) ? [self.dataSource numberOfViews]-1 : _currIndex - 1;
		[self loadPageWithId:_prevIndex onPage:0];
	}
    
	// Reset offset back to middle page
	[_scrollView scrollRectToVisible:CGRectMake(320,0,320,416) animated:NO];
    
//    [self.delegate changedToView:<#(UIView *)#> withIndex:_currIndex];
}


#pragma mark -
#pragma mark Private Methods

- (void)loadPageWithId:(int)index onPage:(int)page
{
	UIView *view = [self.dataSource viewForIndex:index];
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
            _pageTwoView = view;
			break;
        }
		case 2:
        {
            UIView *viewToRemove = [_pageThreeView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
			_pageThreeView = view;
			break;
        }
	}
}

@end




