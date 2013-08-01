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
@property (nonatomic, strong) UIView *composeView; //container view for |ImageView| and |TagView|


// Needed when we want the TagView to adapt to the image size inside UIScrollView
- (CGRect) getImageFrameFromImageView: (UIImageView *)iv;

@end


@implementation TagImageView

- (id)initWithFrame:(CGRect)frame //WithBoxes:(NSArray *)boxes forImage:(UIImage *) image
{
    self = [super initWithFrame:frame];
    if (self) {
        
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
        
        self.tagView = [[TagView alloc] initWithFrame:self.frame];
        self.tagView.delegate = self;
        
        [self.composeView addSubview:self.imageView];
        [self.composeView addSubview:self.tagView];
        [self.zoomScrollView addSubview:self.composeView];
        
        
        [self.zoomScrollView setContentSize:self.zoomScrollView.frame.size];
        
    }
    return self;
}


#pragma mark -
#pragma mark Getters and Setters

- (void) setBoxes:(NSArray *)boxes
{
    if(boxes!=_boxes){
        _boxes = boxes;
        self.tagView.boxes = [NSMutableArray arrayWithArray:boxes];
        for(Box* box in self.tagView.boxes)
            [box setBoxDimensionsForImageSize:self.tagView.frame.size];
        
        [self setNeedsDisplay];
    }
}

-(void) setImage:(UIImage *)image
{
    if(image!=_image){
        _image = image;
        self.imageView.image = image;
        self.tagView.frame = [self getImageFrameFromImageView:self.imageView];
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)aScrollView
{
    return self.composeView;
}

- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    [self.tagView setLineWidthForZoomFactor:scale];
}


#pragma mark -
#pragma mark TagViewDelegate

-(void)selectedAnObject:(BOOL)value
{
    //disable scrolling when a box is selected
    self.zoomScrollView.scrollEnabled = !value;
}

-(void)objectModified
{
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
