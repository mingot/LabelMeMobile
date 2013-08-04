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
    _scrollView.pagingEnabled = YES;
    _scrollView.contentSize = CGSizeMake(960, 460);
    [_scrollView scrollRectToVisible:CGRectMake(320,0,320,460) animated:NO];
    _scrollView.delegate = self;
    
    [self addSubview:_scrollView];
    
    NSLog(@"self.frame: %@", NSStringFromCGRect(self.frame));
    
    // create placeholders for each of our documents
    _pageOneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    _pageTwoView = [[UIView alloc] initWithFrame:CGRectMake(320, 0, 320, 460)];
    _pageThreeView = [[UIView alloc] initWithFrame:CGRectMake(640, 0, 320, 460)];
    
    _pageOneView.backgroundColor = [UIColor redColor];
    _pageTwoView.backgroundColor = [UIColor greenColor];
    _pageThreeView.backgroundColor = [UIColor blueColor];
    
    
//    NSLog(@"total: %d", total);
//    NSLog(@"Loading pages: %d, %d, %d",module(initialIndex - 1,total),module(initialIndex,total),module(initialIndex + 1,total));
    
    [_scrollView addSubview:_pageOneView];
    [_scrollView addSubview:_pageTwoView];
    [_scrollView addSubview:_pageThreeView];
    
    // load all three pages into our scroll view
    int initialIndex = 0;
    int total = [self.dataSource numberOfViews];
    [self loadPageWithId:module(initialIndex - 1,total) onPage:0];
    [self loadPageWithId:module(initialIndex, total) onPage:1];
    [self loadPageWithId:module(initialIndex + 1, total) onPage:2];
}

#pragma mark - 
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{

    int total = [self.dataSource numberOfViews];

    if(_scrollView.contentOffset.x > _scrollView.frame.size.width) {
        // We are moving forward. Load the current doc data on the first page.
        [self loadPageWithId:_currIndex onPage:0];
        // Add one to the currentIndex or reset to 0 if we have reached the end.
        _currIndex = (_currIndex >= total - 1) ? 0 : _currIndex + 1;
        [self loadPageWithId:_currIndex onPage:1];
        // Load content on the last page. This is either from the next item in the array
        // or the first if we have reached the end.
        _nextIndex = (_currIndex >= total - 1) ? 0 : _currIndex + 1;
        [self loadPageWithId:_nextIndex onPage:2];
    }
    if(_scrollView.contentOffset.x < _scrollView.frame.size.width) {
        // We are moving backward. Load the current doc data on the last page.
        [self loadPageWithId:_currIndex onPage:2];
        // Subtract one from the currentIndex or go to the end if we have reached the beginning.
        _currIndex = (_currIndex == 0) ? total - 1 : _currIndex - 1;
        [self loadPageWithId:_currIndex onPage:1];
        // Load content on the first page. This is either from the prev item in the array
        // or the last if we have reached the beginning.
        _prevIndex = (_currIndex == 0) ? total - 1 : _currIndex - 1;
        [self loadPageWithId:_prevIndex onPage:0];
    }
    
    // Reset offset back to middle page
    [_scrollView scrollRectToVisible:CGRectMake(320,0,320,460) animated:NO];
    NSLog(@"Current index:%d", _currIndex);
    
//    //retrieve current view to give it to the delegate
    UIView *currentView = [_pageTwoView viewWithTag:kViewTag];
    [self.delegate changedToView:currentView withIndex:_currIndex];

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
            
//            view.frame = _pageOneView.frame;
//            _pageOneView = view;
//            _pageOneView.subView = view;
			break;
        }
		case 1:
        {
            UIView *viewToRemove = [_pageTwoView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageTwoView addSubview:view];
            
//            view.frame = _pageTwoView.frame;
//            _pageTwoView = view;

//            _pageTwoView.subView = view;
			break;
        }
		case 2:
        {
            UIView *viewToRemove = [_pageThreeView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageThreeView addSubview:view];
            
//            view.frame = _pageThreeView.frame;
//            _pageThreeView = view;
            
//            _pageThreeView.subView = view;
			break;
        }
	}
    
    [self setNeedsDisplay];
}

@end


@implementation PallasadaView

- (id) initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]){
        
        self.subView = [[UIView alloc]  initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [self addSubview:self.subView];
    }
    
    return self;
}

@end




