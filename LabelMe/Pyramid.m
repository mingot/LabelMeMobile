//
//  Pyramid.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 20/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "Pyramid.h"
#import "UIImage+Resize.h"
#import "Classifier.h"


#define SCALES_PER_OCTAVE 10


@interface Pyramid()

//send the average of all the detectors
@property (nonatomic, strong) NSNumber *scaleFactor;

@end



@implementation Pyramid



#pragma mark -
#pragma mark Initialization

- (NSMutableArray *) hogFeatures
{
    if(!_hogFeatures){
        _hogFeatures = [[NSMutableArray alloc] initWithCapacity:self.numPyramids];
        for(int i=0;i<self.numPyramids;i++) [_hogFeatures addObject:[NSNumber numberWithInt:0]]; //null initialization;
    }
    return _hogFeatures;
}


- (NSMutableSet *) levelsToCalculate
{
    if(!_levelsToCalculate){
        _levelsToCalculate = [[NSMutableSet alloc] init];
        for(int i=0;i<self.numPyramids;i++)
            [_levelsToCalculate addObject:[NSNumber numberWithInt:i]];
    }
    return _levelsToCalculate;
}

- (id) initWithClassifiers:(NSArray *)svmClassifiers forNumPyramids:(int)numPyramids
{
    self = [super init];
    if(self){
        self.numPyramids = numPyramids;
        
        //compute average scale factor
        float average = 0;
        for(Classifier *svmClassifier in svmClassifiers)
            average = average + svmClassifier.scaleFactor.floatValue;
        average = average/svmClassifiers.count;
        self.scaleFactor = [NSNumber numberWithFloat:average];
    }
    
    return self;
}

#pragma mark -
#pragma mark Pyramid constructor


- (void) constructPyramidForImage:(UIImage *)image withOrientation:(int)orientation
{
    //rotate image depending on the orientation
    //TODO: take out the orientation of the pyramid!!
    if(UIDeviceOrientationIsLandscape(orientation))
        image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation: UIImageOrientationUp];
    
    //scaling factor for the image
    double initialScale = self.scaleFactor.doubleValue/sqrt(image.size.width*image.size.width);
    double scale = pow(2, 1.0/SCALES_PER_OCTAVE);
    
    UIImage *scaledImage = [image scaleImageTo:initialScale/pow(scale,0)]; //optimize to start to the first true index
    
    //reset all pyramids levels
    self.hogFeatures = nil;
    
    __block HogFeature *imageHog;
    dispatch_queue_t pyramidConstructionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply(self.numPyramids, pyramidConstructionQueue, ^(size_t i) {
        if([self.levelsToCalculate containsObject:[NSNumber numberWithInt:i]]){
            float scaleLevel = pow(1.0/scale, i);
            imageHog = [[scaledImage scaleImageTo:scaleLevel] obtainHogFeatures];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.hogFeatures setObject:imageHog atIndexedSubscript:i];
            });
        }
    });
    dispatch_release(pyramidConstructionQueue);
    
//    NSLog(@"Levels: %@", self.levelsToCalculate);
//    NSLog(@"hog features: %@", self.hogFeatures);
    
    
    
//    for(int i=0; i<self.numPyramids; i++)
//        if([self.levelsToCalculate containsObject:[NSNumber numberWithInt:i]]){
//            float scaleLevel = pow(1.0/scale, i);
//            HogFeature *imageHog = [[scaledImage scaleImageTo:scaleLevel] obtainHogFeatures];
//            [self.hogFeatures setObject:imageHog atIndexedSubscript:i];
//        }
    
    

    //reset indexes to look into
    [self.levelsToCalculate removeAllObjects];
    
}

@end
