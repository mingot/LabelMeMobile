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


- (NSMutableSet *) levelsToCalculate
{
    if(!_levelsToCalculate) _levelsToCalculate = [[NSMutableSet alloc] init];
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
    self.hogFeatures = [[NSMutableArray alloc] init];
    
    //rotate image depending on the orientation
    //TODO: take out the orientation of the pyramid!!
    if(UIDeviceOrientationIsLandscape(orientation))
        image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation: UIImageOrientationUp];
    
    //scaling factor for the image
    double initialScale = self.scaleFactor.doubleValue/sqrt(image.size.width*image.size.width);
    double scale = pow(2, 1.0/SCALES_PER_OCTAVE);
    
    NSLog(@"Levels: %@", self.levelsToCalculate);
    UIImage *scaledImage = [image scaleImageTo:initialScale/pow(scale,0)]; //optimize to start to the first true index
    for(int i=0; i<self.numPyramids; i++)
        if([self.levelsToCalculate containsObject:[NSNumber numberWithInt:i]]){
            float scaleLevel = pow(1.0/scale, i);
            HogFeature *imageHog = [[scaledImage scaleImageTo:scaleLevel] obtainHogFeatures];
            [self.hogFeatures addObject:imageHog];
        }else [self.hogFeatures addObject:[NSNumber numberWithInt:0]]; //insert null
    

    //reset indexes to look into
    self.levelsToCalculate = nil;
    
}

@end
