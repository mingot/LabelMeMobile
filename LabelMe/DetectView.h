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

// ConvolutionPoint Array of the detected boxes
@property (nonatomic,strong) NSArray *corners;
// To transform a point from the device reference to prevLayer reference
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *prevLayer;


- (void)reset;

@end
