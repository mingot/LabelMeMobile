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
#import "ConvolutionHelper.h"

#define TEMPLATE_SCALE_FACTOR 0.2 //resize template to obtain a reasonable number of blocks for the hog features

#define MAX_NUMBER_EXAMPLES 20000
#define MAX_NUMBER_FEATURES 2000

@implementation TrainingSet

@synthesize images = _images;
@synthesize groundTruthBoundingBoxes = _groundTruthBoundingBoxes;
@synthesize boundingBoxes = _boundingBoxes;
@synthesize imageFeatures = _imageFeatures;
@synthesize labels = _labels;
@synthesize templateSize = _templateSize;

- (void) setTemplateSize:(CGSize)templateSize
{
    _templateSize = templateSize;
}


- (CGSize) templateSize
{
    //compute template size in case it is not set (lazy instantiation)
    if(_templateSize.height == 0.0){
        NSLog(@"Computing template size...");
        CGSize averageSize;
        averageSize.height = 0;
        averageSize.width = 0;
        
        for(BoundingBox* groundTruthBB in self.groundTruthBoundingBoxes){
            averageSize.height += groundTruthBB.ymax - groundTruthBB.ymin;
            averageSize.width += groundTruthBB.xmax - groundTruthBB.xmin;
        }
        
        //compute the average and get the average size in the image dimensions
        CGSize imgSize = [[self.images objectAtIndex:0] size];
        averageSize.height = averageSize.height*imgSize.height*TEMPLATE_SCALE_FACTOR/self.groundTruthBoundingBoxes.count;
        averageSize.width = averageSize.width*imgSize.width*TEMPLATE_SCALE_FACTOR/self.groundTruthBoundingBoxes.count;
        
        HogFeature *hog = [[[self.images objectAtIndex:0] resizedImage:averageSize interpolationQuality:kCGInterpolationDefault] obtainHogFeatures];
        
        _templateSize = averageSize;
        
        NSLog(@"Template size setted: h:%f, w:%f", _templateSize.height, _templateSize.width);
        NSLog(@"Hog features size: %d, %d, %d", hog.numBlocksX, hog.numBlocksY, hog.numFeaturesPerBlock);
    }
    return _templateSize;
}


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

- (void) initialFill
{
    self.boundingBoxes = [[NSMutableArray alloc] initWithArray:self.groundTruthBoundingBoxes];
    
    for(BoundingBox *groundTruth in self.groundTruthBoundingBoxes){
        
        //TODO: suposing just one ground truth per image
        UIImage *image = [self.images objectAtIndex:groundTruth.imageIndex];
        
        //the new box will have the size of the template size (not necessary though)
        float height = self.templateSize.height/image.size.height;
        float width = self.templateSize.width/image.size.width;
        
        double randomX;
        double randomY;
        
        int num=20;
        for(int j=0; j<num/2;j++){
            
            if(j%4==0){
                randomX = 0;
                randomY = j*1.0/num;
            }else if(j%4==1){
                randomX = j*1.0/num;
                randomY = 0;
            }else if(j%4==2){
                randomX = 1 - width;
                randomY = j*1.0/num;
            }else{
                randomX = j*1.0/num;
                randomY = 1-height;
            }
            
            BoundingBox *negativeExample = [[BoundingBox alloc] initWithRect:CGRectMake(randomX, randomY, width, height) label:-1 imageIndex:groundTruth.imageIndex];
            
            if([negativeExample fractionOfAreaOverlappingWith:groundTruth]<0.1)
                [self.boundingBoxes addObject:negativeExample];
        }
        
        
        self.numberOfTrainingExamples = self.boundingBoxes.count;
    }
}



- (void) generateFeaturesForBoundingBoxesWithNumSV:(int)numSV
{
    // transform each bounding box into hog feature space
    int i;
    CGSize currentTemplateSize = self.templateSize;
    
    for(i=0; i<self.boundingBoxes.count; i++)
    {
        @autoreleasepool
        {
            BoundingBox *boundingBox = [self.boundingBoxes objectAtIndex:i];
            if(i%1000 == 0) NSLog(@"evolution %.1f",i*100.0/self.boundingBoxes.count);
            //get the image contained in the bounding box and resized it with the template size
            UIImage *wholeImage = [self.images objectAtIndex:boundingBox.imageIndex];
            UIImage *resizedImage = [[wholeImage croppedImage:[boundingBox rectangleForImage:wholeImage]] resizedImage:currentTemplateSize interpolationQuality:kCGInterpolationDefault];
            
            //calculate the hogfeatures of the image
            HogFeature *hogFeature = [resizedImage obtainHogFeatures];
            
            //check if it has enough space to allocate it
            if((i+1+numSV)*hogFeature.totalNumberOfFeatures > MAX_NUMBER_EXAMPLES*MAX_NUMBER_FEATURES*sizeof(float))
            {
                NSLog(@"BUFFER FULL!!");
                break;
            }
            
            //add the label
            self.labels[numSV + i] = (float) boundingBox.label;
            
            //add the hog features
            for(int j=0; j<hogFeature.totalNumberOfFeatures; j++)
                self.imageFeatures[(numSV + i)*hogFeature.totalNumberOfFeatures + j] = (float) hogFeature.features[j];
        }
        
    }
    self.numberOfTrainingExamples = numSV + i;
}

@end


