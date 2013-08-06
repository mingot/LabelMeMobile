                                                                                                                                                                                  //
//  DetectView.h
//  ImageG
//
//  Created by Dolores Blanco Almazán on 12/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface DetectView : UIView

// Array of arrays. Subarrays contanin bb for each different class.
@property (nonatomic,strong) NSArray *cornersArray;

// To transform a point from the device reference to prevLayer reference
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;

//targetclass -> UIColor
@property (nonatomic, strong) NSDictionary *colorsDictionary;

//Camera specifics to help place the boxes
@property int cameraOrientation;
@property BOOL frontCamera;

- (void)reset;


@end

