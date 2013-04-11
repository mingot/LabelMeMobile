//
//  ThreeDimVC.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 11/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ThreeDimVC : UIViewController

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSTimer *timer;


@property (strong, nonatomic) NSArray *imageList;
@property (strong, nonatomic) NSDictionary *positionsDic;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@end
