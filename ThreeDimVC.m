//
//  ThreeDimVC.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 11/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "ThreeDimVC.h"



@implementation ThreeDimVC

@synthesize imageList = _imageList;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageView.contentMode = UIViewContentModeCenter;
//    self.imageView.image = [self.imageList objectAtIndex:0];
    
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(timerUpdate)
                                           userInfo:nil
                                            repeats:YES];
    //load all the images;
    
}


-(void) timerUpdate
{
    //read device motion to updat images
    CMAttitude *attitude = self.motionManager.deviceMotion.attitude;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *key = [NSString stringWithFormat:@"%d_%d",20 + (int)round(attitude.pitch*10),20 + (int)round(attitude.roll*10)];
        UIImage *image = [self.positionsDic objectForKey:key];
        if(image){
            self.imageView.image = image;
        }
    });
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        int pitch = round(self.motionManager.deviceMotion.attitude.pitch*10);
//        if(pitch>0 && pitch <self.imageList.count)
//            self.imageView.image = [self.imageList objectAtIndex:pitch];
//        [self.view setNeedsDisplay];
//        NSLog(@"pitch:%d", pitch);
//    });

}


@end
