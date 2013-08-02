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
    NSString *_username;
    NSString *_imagePath;
    NSString *_boxesPath;
    NSString *_thumbnailPath;
    NSMutableDictionary *_userDictionary;
    int _dictionaryValue;
}

@end


@implementation FilenameResourcesHandler


@synthesize boxesNotSent = _boxesNotSent;

- (id) initForUsername:(NSString *)username andFilename:(NSString *) filename
{
    if(self = [super init]){
        _paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:username]];
        _userDictionary = [[NSMutableDictionary alloc]initWithContentsOfFile:[[_paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",username]];;
        self.filename = filename;
        
        _username = username;
    }
    return self;
}


- (void) setFilename:(NSString *)filename
{
    if(filename!=_filename){
        _imagePath = [[_paths objectAtIndex:IMAGES] stringByAppendingPathComponent:filename];
        _boxesPath = [[_paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
        _thumbnailPath = [[_paths objectAtIndex:THUMB] stringByAppendingPathComponent:filename];
        _dictionaryValue = [[_userDictionary objectForKey:filename] intValue];
        _boxesNotSent = _dictionaryValue > -1 ? _dictionaryValue : abs(_dictionaryValue) - 1;
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

- (BOOL)imageNotSent
{
    return _dictionaryValue < 0;
}

- (int) boxesNotSent
{
    return _boxesNotSent;
}

- (void) setBoxesNotSent:(int)boxesNotSent
{
    if(_boxesNotSent != boxesNotSent)
    {
        _boxesNotSent = boxesNotSent;
        
        //update dictionary values
        int dictValue;
        if([self imageNotSent]) dictValue = - (1 + boxesNotSent);
        else dictValue = boxesNotSent;
        
        //save it to a file
        [_userDictionary setObject:[NSNumber numberWithInt:dictValue] forKey:_filename];
        [_userDictionary writeToFile:[[_paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",_username] atomically:NO];
    }
}

@end
