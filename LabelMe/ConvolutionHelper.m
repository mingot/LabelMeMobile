//
//  ConvolutionHelper.m
//  TestDetector
//
//  Created by Josep Marc Mingot Hidalgo on 07/02/13.
//  Copyright (c) 2013 Dolores. All rights reserved.
//

#include <Accelerate/Accelerate.h>
#import "ConvolutionHelper.h"
#import "UIImage+HOG.h"


static inline double min(double x, double y) { return (x <= y ? x : y); }
static inline double max(double x, double y) { return (x <= y ? y : x); }
static inline int min_int(int x, int y) { return (x <= y ? x : y); }
static inline int max_int(int x, int y) { return (x <= y ? y : x); }


@implementation BoundingBox

@synthesize score = _score;
@synthesize ymin = _ymin;
@synthesize ymax = _ymax;
@synthesize xmin = _xmin;
@synthesize xmax = _xmax;
@synthesize label = _label;
@synthesize imageIndex = _imageIndex;
@synthesize pyramidLevel = _pyramidLevel;
@synthesize rectangle = _rectangle;
@synthesize locationOnImageHog = _locationOnImageHog;
@synthesize imageHogIndex = _imageHogIndex;

-(id) initWithRect:(CGRect)initialRect label:(int)label imageIndex:(int)imageIndex;
{
    if(self = [self init])
    {
//        self.label = label;
        self.imageIndex = imageIndex;
        self.xmin = initialRect.origin.x;
        self.xmax = initialRect.origin.x + initialRect.size.width;
        self.ymin = initialRect.origin.y;
        self.ymax = initialRect.origin.y + initialRect.size.height;
    }
    return self;
}

-(id) initWithBoundingBox:(BoundingBox *)box
{
    if(self = [self init]){
        self.score = box.score;
        self.xmin = box.xmin;
        self.xmax = box.xmax;
        self.ymin = box.ymin;
        self.ymax = box.ymax;
        self.label = box.label;
        self.imageIndex = box.imageIndex;
        self.pyramidLevel = box.pyramidLevel;
        self.rectangle = box.rectangle;
        self.locationOnImageHog = box.locationOnImageHog;
        self.targetClass = box.targetClass;
        self.imageIndex = box.imageHogIndex;
    }
    return self;
}

- (CGRect) rectangle
{
    return CGRectMake(self.xmin, self.ymin, self.xmax - self.xmin, self.ymax - self.ymin);
}

- (CGRect) rectangleForImage:(UIImage *)image
{
    return CGRectMake(self.xmin*image.size.width, self.ymin*image.size.height, (self.xmax - self.xmin)*image.size.width, (self.ymax - self.ymin)*image.size.height);
}

- (void) setRectangle:(CGRect)rectangle
{
    _rectangle = rectangle;
}

- (double) fractionOfAreaOverlappingWith:(BoundingBox *) cp
{
    double area1, area2, unionArea, intersectionArea, a, b;
    
    area1 = (self.xmax - self.xmin)*(self.ymax - self.ymin);
    area2 = (cp.xmax - cp.xmin)*(cp.ymax - cp.ymin);
    
    a = (min(self.xmax, cp.xmax) - max(self.xmin, cp.xmin));
    b = (min(self.ymax, cp.ymax) - max(self.ymin, cp.ymin));
    intersectionArea = (a>0 && b>0) ? a*b : 0;
    unionArea = area1 + area2 - intersectionArea;
//    if (intersectionArea == area1 || intersectionArea == area2) //one bb contain the other
//        intersectionArea = unionArea;
    
    return intersectionArea/unionArea>0 ? intersectionArea/unionArea : 0;
}


- (BoundingBox *)increaseSizeByFactor:(float)factor
{
    BoundingBox *newBox = [[BoundingBox alloc] initWithBoundingBox:self];
    CGFloat newWidth = (newBox.xmax - newBox.xmin)*(1 + factor);
    CGFloat newHeight = (newBox.ymax - newBox.ymin)*(1 + factor);
    CGFloat midX = (newBox.xmin + newBox.xmax)/2.0;
    CGFloat midY = (newBox.ymin + newBox.ymax)/2.0;
    
    newBox.xmax = min(midX + newWidth/2, 1);
    newBox.ymax = min(midY + newHeight/2, 1);
    newBox.xmin = max(midX - newWidth/2, 0);
    newBox.ymin = max(midY - newHeight/2, 0);
    return newBox;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"upperLeft = (%.2f,%.2f), lowerRight = (%.2f,%.2f)",self.xmin, self.ymin, self.xmax, self.ymax];
}

@end



@implementation ConvolutionHelper


+ (void) convolution:(double *)result matrixA:(double *)matrixA :(int *)sizeA matrixB:(double *)matrixB :(int *)sizeB
{
    int convolutionSize[2];
    convolutionSize[0] = sizeA[0] - sizeB[0] + 1; 
    convolutionSize[1] = sizeA[1] - sizeB[1] + 1;
    
    for (int x = 0; x < convolutionSize[1]; x++) {
        for (int y = 0; y < convolutionSize[0]; y++)
        {
            double val = 0;
            
            for(int xp=0;xp<sizeB[1];xp++){ //Assuming column-major representation
                double *A_off = matrixA + (x+xp)*sizeA[0] + y;
                double *B_off = matrixB + xp*sizeB[0];
                switch(sizeB[0]) { //depending on the template size sizeB[0]. Use this hack to avoid an additional loop in common cases.
                    case 20: val += A_off[19] * B_off[19];
                    case 19: val += A_off[18] * B_off[18];
                    case 18: val += A_off[17] * B_off[17];
                    case 17: val += A_off[16] * B_off[16];
                    case 16: val += A_off[15] * B_off[15];
                    case 15: val += A_off[14] * B_off[14];
                    case 14: val += A_off[13] * B_off[13];
                    case 13: val += A_off[12] * B_off[12];
                    case 12: val += A_off[11] * B_off[11];
                    case 11: val += A_off[10] * B_off[10];
                    case 10: val += A_off[9]  * B_off[9];
                    case 9:  val += A_off[8]  * B_off[8];
                    case 8:  val += A_off[7]  * B_off[7];
                    case 7:  val += A_off[6]  * B_off[6];
                    case 6:  val += A_off[5]  * B_off[5];
                    case 5:  val += A_off[4]  * B_off[4];
                    case 4:  val += A_off[3]  * B_off[3];
                    case 3:  val += A_off[2]  * B_off[2];
                    case 2:  val += A_off[1]  * B_off[1];
                    case 1:  val += A_off[0]  * B_off[0];
                        break;
                    default:
                        for (int yp = 0; yp < sizeB[0]; yp++) {
                            val += *(A_off++) * *(B_off++);
                        }
                }
            }
            *(result++) += val;
            
        }
    }
}


+ (NSArray *) nms:(NSArray *)boundingBoxesCandidates
   maxOverlapArea:(double)overlap
minScoreThreshold:(double)scoreThreshold
{

    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    // select only those bounding boxes with score above the threshold and non overlapping areas
    for (int i = 0; i<boundingBoxesCandidates.count; i++){
        BOOL selected = YES;
        BoundingBox *point = [boundingBoxesCandidates objectAtIndex:i];
    
        if (point.score < scoreThreshold)
            break;
        
        for (int j = 0; j<result.count; j++)
            if ([[result objectAtIndex:j] fractionOfAreaOverlappingWith:point] > overlap){
                selected = NO;
                break;
            }
        
        if (selected) [result addObject:point];
    }
    
    return result;
}


@end
