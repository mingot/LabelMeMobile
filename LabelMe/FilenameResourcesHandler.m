//
//  ResourcesHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "FilenameResourcesHandler.h"
#import "NSObject+Folders.h"

#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define USER 3

@interface FilenameResourcesHandler()
{
    NSArray *_paths;
    NSString *_imagePath;
    NSString *_boxesPath;
    NSString *_thumbnailPath;
}

@end


@implementation FilenameResourcesHandler


- (id) initForUsername:(NSString *)username andFilename:(NSString *) filename
{
    if(self = [super init]){
        _paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:username]];
        self.filename = filename;
    }
    return self;
}


- (void) setFilename:(NSString *)filename
{
    if(filename!=_filename){
        _imagePath = [[_paths objectAtIndex:IMAGES] stringByAppendingPathComponent:filename];
        _boxesPath = [[_paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
        _thumbnailPath = [[_paths objectAtIndex:THUMB] stringByAppendingPathComponent:filename];
    }
}



- (NSArray *) getBoxes
{
    return [[NSArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:_boxesPath]];
}
    
- (UIImage *) getImage
{
    return [[UIImage alloc] initWithContentsOfFile:_imagePath];
}


- (void) saveThumbnail:(UIImage *)thumbnail
{
    dispatch_queue_t saveQueue = dispatch_queue_create("saveQueue", NULL);
    dispatch_sync(saveQueue, ^{
        NSData *thumImage = UIImageJPEGRepresentation(thumbnail, 0.75);
        [[NSFileManager defaultManager] createFileAtPath:_thumbnailPath contents:thumImage attributes:nil];
    });
    dispatch_release(saveQueue);
}

- (void) saveImage:(UIImage *)image
{
    
}

- (void) saveBoxes:(NSArray *)boxes
{
    dispatch_queue_t saveQueue = dispatch_queue_create("saveQueue", NULL);
    dispatch_sync(saveQueue, ^{
        [NSKeyedArchiver archiveRootObject:boxes toFile:_boxesPath];
    });
    dispatch_release(saveQueue);
    
}


@end
