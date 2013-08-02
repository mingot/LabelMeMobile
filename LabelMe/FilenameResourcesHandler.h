//
//  ResourcesHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

// For the current filename and username it serves the necessary resources


#import <Foundation/Foundation.h>

@interface FilenameResourcesHandler : NSObject

@property (nonatomic, strong) NSString *filename;
@property int boxesNotSent;


- (id) initForUsername:(NSString *)username andFilename:(NSString *) filename;

- (NSArray *) getBoxes;
- (UIImage *) getImage;
//- (UIImage *) getThumbnail;

- (void) saveThumbnail:(UIImage *)thumbnail;
- (void) saveImage:(UIImage *)image;
- (void) saveBoxes:(NSArray *)boxes;

- (BOOL) imageNotSent;


@end
