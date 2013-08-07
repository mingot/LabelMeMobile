//
//  TrainingSet.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "TrainingSet.h"
#import "UIImage+HOG.h"
#import "UIImage+Resize.h"
#import "BoundingBox.h"

#define TEMPLATE_SCALE_FACTOR 0.1 //resize template to obtain a reasonable number of blocks for the hog features

#define MAX_NUMBER_EXAMPLES 20000
#define MAX_NUMBER_FEATURES 2000

@interface TrainingSet()

- (void) setInternals;

@end



@implementation TrainingSet

@synthesize images = _images;
@synthesize groundTruthBoundingBoxes = _groundTruthBoundingBoxes;
@synthesize boundingBoxes = _boundingBoxes;
@synthesize imageFeatures = _imageFeatures;
@synthesize labels = _labels;
@synthesize templateSize = _templateSize;
@synthesize areaRatio = _areaRatio;


#pragma mark 
#pragma mark - Setters and Getters

-(void) setAreaRatio:(float)areaRatio
{
    _areaRatio = areaRatio;
}

-(float) areaRatio
{
    if (_areaRatio == 0.0) [self setInternals];
    
    return _areaRatio;
}


- (void) setTemplateSize:(CGSize)templateSize
{
    _templateSize = templateSize;
}

- (CGSize) templateSize
{
    //compute template size in case it is not set (lazy instantiation)
    if(_templateSize.height == 0.0) [self setInternals];
    
    return _templateSize;
}


#pragma mark
#pragma mark - Initialization

-(id) init
{
    self = [super init];
    if (self) {
        self.images = [[NSMutableArray alloc] init];
        self.groundTruthBoundingBoxes = [[NSMutableArray alloc] init];
        self.boundingBoxes = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark   
#pragma mark - Private methods

-(void) setInternals
{
    CGSize averageSize;
    averageSize.height = 0;
    averageSize.width = 0;
    
    for(BoundingBox* groundTruthBB in self.groundTruthBoundingBoxes){
        averageSize.height += groundTruthBB.ymax - groundTruthBB.ymin;
        averageSize.width += groundTruthBB.xmax - groundTruthBB.xmin;
    }
    
    _areaRatio = averageSize.height*averageSize.width/(self.groundTruthBoundingBoxes.count * self.groundTruthBoundingBoxes.count);
    
    //compute the average and get the average size in the image dimensions
    CGSize imgSize = [[self.images objectAtIndex:0] size];
    averageSize.height = averageSize.height*imgSize.height*TEMPLATE_SCALE_FACTOR/self.groundTruthBoundingBoxes.count;
    averageSize.width = averageSize.width*imgSize.width*TEMPLATE_SCALE_FACTOR/self.groundTruthBoundingBoxes.count;
    
    _templateSize = averageSize;
    
}

- (void) unifyGroundTruthBoundingBoxes
{
//    NSMutableArray *newGroundTruthBB = [[NSMutableArray alloc] init];
    
    //get max width and max height of the gt bb
    float maxWidth=0, maxHeight=0;
    for(BoundingBox *groundTruthBB in self.groundTruthBoundingBoxes){
        float width = groundTruthBB.xmax - groundTruthBB.xmin;
        float height = groundTruthBB.ymax - groundTruthBB.ymin;
        maxWidth = maxWidth > width ? maxWidth : width;
        maxHeight = maxHeight > height ? maxHeight : height;
    }
    
    //modify the actual bb
    for(BoundingBox *groundTruthBB in self.groundTruthBoundingBoxes){
        float xMidPoint = (groundTruthBB.xmax + groundTruthBB.xmin)/2;
        float yMidPoint = (groundTruthBB.ymax + groundTruthBB.ymin)/2;
        groundTruthBB.xmin = xMidPoint - maxWidth/2;
        groundTruthBB.xmax = xMidPoint + maxWidth/2;
        groundTruthBB.ymin = yMidPoint - maxHeight/2;
        groundTruthBB.ymax = yMidPoint + maxHeight/2;
    }
}



@end


