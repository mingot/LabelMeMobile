//
//  InfiniteLoopView.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "InfiniteLoopView.h"
#import "DictionaryQueue.h"

#define module(a, b) (a >= 0) ? (a)%b : ((a)%(b) + b)
#define kViewTag 10
#define kQueueDictionaryCapacity 10 //views to store in the internal dictionary
#define kWidth self.frame.size.width
#define kHeight self.frame.size.height

@interface InfiniteLoopView()
{
    UIScrollView *_scrollView;
    UIView *_pageOneView;
    UIView *_pageTwoView;
    UIView *_pageThreeView;
    int _currIndex;
    int _prevIndex;
    int _nextIndex;
    DictionaryQueue *_viewsQueue; //enqueue views to not continuosly ask the data source
}

@end


@implementation InfiniteLoopView

- (void) initializeAtIndex:(int) initialIndex;
{
    
    _viewsQueue = [[DictionaryQueue alloc] initWithCapcity:kQueueDictionaryCapacity];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    _scrollView.pagingEnabled = YES;
    _scrollView.contentSize = CGSizeMake(3*kWidth, kHeight);
    [_scrollView scrollRectToVisible:CGRectMake(kWidth,0,kWidth,kHeight) animated:NO];
    _scrollView.delegate = self;
    
    [self addSubview:_scrollView];
    
    // create placeholders for each of our documents
    _pageOneView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
    _pageTwoView = [[UIView alloc] initWithFrame:CGRectMake(1*kWidth, 0, kWidth, kHeight)];
    _pageThreeView = [[UIView alloc] initWithFrame:CGRectMake(2*kWidth, 0, kWidth, kHeight)];
    
    _pageOneView.backgroundColor = [UIColor blackColor];
    _pageTwoView.backgroundColor = [UIColor blackColor];
    _pageThreeView.backgroundColor = [UIColor blackColor];
    
    [_scrollView addSubview:_pageOneView];
    [_scrollView addSubview:_pageTwoView];
    [_scrollView addSubview:_pageThreeView];
    
    // load all three pages into our scroll view
    int total = [self.dataSource numberOfViews];
    [self loadPageWithId:module(initialIndex - 1,total) onPage:0];
    [self loadPageWithId:module(initialIndex, total) onPage:1];
    [self loadPageWithId:module(initialIndex + 1, total) onPage:2];
    _currIndex = initialIndex;
    NSLog(@"Going to load: %d, %d, %d",module(initialIndex - 1,total),module(initialIndex,total),module(initialIndex + 1,total) );
    
    // notify about the first view

    UIView *currentView = [_pageTwoView viewWithTag:kViewTag];
    [self.delegate didShowView:currentView forIndex:_currIndex];

}

#pragma mark - 
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{

    int total = [self.dataSource numberOfViews];

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
    [_scrollView scrollRectToVisible:CGRectMake(1*kWidth,0,kWidth,kHeight) animated:NO];
    
    //inform the delegate of the change
    UIView *currentView = [_pageTwoView viewWithTag:kViewTag];
    [self.delegate didShowView:currentView forIndex:_currIndex];

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
	UIView *view = [_viewsQueue objectForKey:[NSNumber numberWithInt:index]];
    if(view == nil){
        view = [self.dataSource viewForIndex:index];
        [_viewsQueue enqueueObject:view forKey:[NSNumber numberWithInt:index]];
    }
    
//    UIView *view = [self.dataSource viewForIndex:index];
    view.frame = _pageOneView.frame;
    view.tag = kViewTag;
    
    
    // load data for page
    UIView *viewToRemove;
    switch (page) {
		case 0:
            viewToRemove = [_pageOneView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageOneView addSubview:view];
			break;
		case 1:
            viewToRemove = [_pageTwoView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageTwoView addSubview:view];
			break;
		case 2:
            viewToRemove = [_pageThreeView viewWithTag:kViewTag];
            [viewToRemove removeFromSuperview];
            [_pageThreeView addSubview:view];
			break;
	}
    
    [self setNeedsDisplay];
}

@end





