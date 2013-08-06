//
//  DetectorResourceFileHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorResourceHandler.h"

#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define DETECTORS 3

@interface DetectorResourceHandler()
{
    NSString *_username;
    NSString *_userPath;
    NSArray *_resourcesPaths;
}


@end



@implementation DetectorResourceHandler

#pragma mark -
#pragma mark Initialization

- (id)initForUsername:(NSString *) username
{
    if (self = [super init]) {
        
        _username = username;
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _userPath = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,_username];
        
        _resourcesPaths = [NSArray arrayWithObjects:
                           [_userPath stringByAppendingPathComponent:@"images"],
                           [_userPath stringByAppendingPathComponent:@"thumbnail"],
                           [_userPath stringByAppendingPathComponent:@"annotations"],
                           [_userPath stringByAppendingPathComponent:@"Detectors"],
                           _userPath, nil];
        
    }
    return self;
}


#pragma mark -
#pragma mark Public methods

- (NSArray *) getAvailanleObjectClasses
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[_resourcesPaths objectAtIndex:THUMB]] error:NULL];
    
    for(NSString *imageName in imagesList){
        NSString *path = [[_resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
        NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
        for(Box *box in objects)
            if([list indexOfObject:box.label] == NSNotFound && ![box.label isEqualToString:@""])
                [list addObject:box.label];
    }
    
    return [NSArray arrayWithArray:list];
    
}

- (NSArray *) getImagesList
{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_userPath stringByAppendingPathComponent:@"thumbnail"] error:NULL];
}

- (NSMutableArray *) loadDetectors
{
    NSMutableArray *detectors;
    
    //load detectors and create directory if it does not exist
    NSString *detectorsPath = [_userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"];
    detectors = [NSKeyedUnarchiver unarchiveObjectWithFile:detectorsPath];
    if(!detectors) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[_userPath stringByAppendingPathComponent:@"Detectors"] withIntermediateDirectories:YES attributes:nil error:nil];
        detectors = [[NSMutableArray alloc] init];
    }
    
    return detectors;
}

- (void) saveDetectors:(NSArray *) detectors
{
    if(![NSKeyedArchiver archiveRootObject:detectors toFile:[_userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"]])
        NSLog(@"Unable to save the classifiers");
}

- (void) removeImageForDetector:(Classifier *) detector
{
    NSString *bigImagePath = [_userPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Detectors/%@_big.jpg", detector.classifierID]];
    NSString *thumbnailImagePath = [_userPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Detectors/%@_thumb.jpg", detector.classifierID]];
    [[NSFileManager defaultManager] removeItemAtPath:bigImagePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:thumbnailImagePath error:nil];
}


@end
