//
//  TagImageView.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 31/07/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "TagImageView.h"


@interface TagImageView()
{
    
}

@property (nonatomic, strong) UIScrollView *zoomScrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *composeView; //container view for |imageView| and |zoomScrollView|


// Needed when we want the TagView to adapt to the image size inside UIScrollView
- (CGRect) getImageFrameFromImageView: (UIImageView *)iv;

@end


@implementation TagImageView

- (id)initWithFrame:(CGRect)frame WithBoxes:(NSArray *)boxes forImage:(UIImage *) image
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.image = image;
        self.boxes = boxes;
    
        self.zoomScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
        [self.zoomScrollView setBackgroundColor:[UIColor blackColor]];
        [self.zoomScrollView setCanCancelContentTouches:NO];
        self.zoomScrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        self.zoomScrollView.clipsToBounds = YES;
        self.zoomScrollView.minimumZoomScale = 1.0;
        self.zoomScrollView.maximumZoomScale = 10.0;
        self.zoomScrollView.delegate = self;
        [self addSubview:self.zoomScrollView];
        
        self.composeView = [[UIView alloc] initWithFrame:self.frame];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = self.image;
        
        
        
        self.tagView = [[TagView alloc] initWithFrame:[self getImageFrameFromImageView:self.imageView]];
        self.tagView.boxes = [NSMutableArray arrayWithArray:self.boxes];
        for(Box* box in self.tagView.boxes)
            [box setBoxDimensionsForImageSize:self.tagView.frame.size];
        
        [self.composeView addSubview:self.imageView];
        [self.composeView addSubview:self.tagView];
        [self.zoomScrollView addSubview:self.composeView];
        
        
        [self.zoomScrollView setContentSize:self.zoomScrollView.frame.size];
        
    }
    return self;
}


#pragma mark -
#pragma mark Scroll View Delegate


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView
{
    return self.composeView;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self.tagView setLineWidthForZoomFactor:scale];
}

#pragma mark -
#pragma mark Private Methods

- (CGRect) getImageFrameFromImageView: (UIImageView *)iv
{
    CGSize imageSize = iv.image.size;
    CGFloat imageScale = fminf(CGRectGetWidth(iv.bounds)/imageSize.width, CGRectGetHeight(iv.bounds)/imageSize.height);
    CGSize scaledImageSize = CGSizeMake(imageSize.width*imageScale, imageSize.height*imageScale);
    CGRect imageFrame = CGRectMake(floorf(0.5f*(CGRectGetWidth(iv.bounds)-scaledImageSize.width)), floorf(0.5f*(CGRectGetHeight(iv.bounds)-scaledImageSize.height)), scaledImageSize.width, scaledImageSize.height);
    
    return imageFrame;
}

@end
