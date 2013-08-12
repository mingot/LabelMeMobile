//
//  ResourcesHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "LabelsResourcesHandler.h"
#import "NSObject+Folders.h"

#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define USER 3


@interface LabelsResourcesHandler()
{
    NSArray *_paths;
    NSString *_username;
    NSString *_imagePath;
    NSString *_boxesPath;
    NSString *_thumbnailPath;
    NSMutableDictionary *_userDictionary;
    
    // 0: Image sent, 0 boxes to be sent
    // n: Image sent, n boxes to be sent
    // -n: Image not sent, (n-1) boxes to be sent
    // e.g.: -1: Image not sent, 0 boxes to be sent
    int _dictionaryValue;
}

@end


@implementation LabelsResourcesHandler


@synthesize boxesNotSent = _boxesNotSent;
@synthesize isImageSent = _isImageSent;



#pragma mark -
#pragma mark Initialization

- (id) initForUsername:(NSString *)username andFilename:(NSString *) filename
{
    if(self = [super init]){
        _paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:username]];
        _username = username;
        
        self.filename = filename;
    }
    return self;
}


- (void) setFilename:(NSString *)filename
{
    if(filename!=_filename){
        _filename = filename;
        _userDictionary = [[NSMutableDictionary alloc]initWithContentsOfFile:[[_paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",_username]];
        _imagePath = [[_paths objectAtIndex:IMAGES] stringByAppendingPathComponent:filename];
        _boxesPath = [[_paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
        _thumbnailPath = [[_paths objectAtIndex:THUMB] stringByAppendingPathComponent:filename];
        
        _dictionaryValue = [[_userDictionary objectForKey:_filename] intValue];
        _isImageSent = _dictionaryValue > -1;
        _boxesNotSent = _isImageSent ? _dictionaryValue : abs(_dictionaryValue) - 1;
    }
}


#pragma mark -
#pragma mark Getters and Setters

- (int) boxesNotSent
{
    return _boxesNotSent;
}

- (void) setBoxesNotSent:(int)boxesNotSent
{
    
    _boxesNotSent = boxesNotSent;
    
    //update dictionary values
    if(!self.isImageSent) _dictionaryValue = - (1 + boxesNotSent);
    else _dictionaryValue = boxesNotSent;
    
    //save it to a file
    [_userDictionary setObject:[NSNumber numberWithInt:_dictionaryValue] forKey:_filename];
    [_userDictionary writeToFile:[[_paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",_username] atomically:NO];
}

- (BOOL) isImageSent
{
    return _isImageSent;
}

- (void) setIsImageSent:(BOOL)isImageSent;
{
    if (isImageSent) {
        _isImageSent = YES;
        _dictionaryValue = 0;
        _boxesNotSent = 0;
        
        //save it to a file
        [_userDictionary setObject:[NSNumber numberWithInt:_dictionaryValue] forKey:_filename];
        [_userDictionary writeToFile:[[_paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",_username] atomically:NO];
    }
}

#pragma mark -
#pragma mark Public Methods

- (NSArray *) getBoxes
{
    return [[NSArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:_boxesPath]];
}
    
- (UIImage *) getImage
{
    return [[UIImage alloc] initWithContentsOfFile:_imagePath];
}

- (NSString *) getBoxesPath
{
    return [_paths objectAtIndex:OBJECTS];
}

- (void) saveThumbnail:(UIImage *)thumbnail
{
    NSData *thumImage = UIImageJPEGRepresentation(thumbnail, 0.75);
    [[NSFileManager defaultManager] createFileAtPath:_thumbnailPath contents:thumImage attributes:nil];
}

- (void) saveBoxes:(NSArray *)boxes
{

    [NSKeyedArchiver archiveRootObject:boxes toFile:_boxesPath];
}

@end
