//
//  ResourcesHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

// For the current filename and username it serves the necessary resources


#import <Foundation/Foundation.h>

@interface LabelsResourcesHandler : NSObject

@property (nonatomic, strong) NSString *filename;
@property int boxesNotSent;
@property BOOL isImageSent;


- (id) initForUsername:(NSString *)username andFilename:(NSString *) filename;

- (NSArray *) getBoxes;
- (UIImage *) getImage;

- (void) saveThumbnail:(UIImage *)thumbnail;
- (void) saveBoxes:(NSArray *)boxes;

//TODO: not to be used
- (NSString *) getBoxesPath;


@end
