//
//  VideoSender.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoSender : NSObject


- (id) initWithServerAddress:(NSString *)address;
- (void) sendImageToServer:(UIImage *)image;


@end
