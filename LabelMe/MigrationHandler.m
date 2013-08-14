//
//  MigrationHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 14/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "MigrationHandler.h"
#import "SendingView.h"  
#import "Box.h"
#import "NSObject+Folders.h"


#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define USER 3

@interface MigrationHandler()
{
    SendingView *_sendingView;
    ServerConnection *_serverConnection;
    
    NSString *_username;
    NSArray *_paths;    
    NSDictionary *_userDictionary;
    NSArray *_filenames;
}


@end

@implementation MigrationHandler


#pragma mark -
#pragma mark Initialization

- (id)initWithUsername:(NSString *) username withSendingView:(SendingView *)sendingView
{

    if (self = [super init]) {
        
        if (![@"2" isEqualToString:[[NSUserDefaults standardUserDefaults]
                                    objectForKey:@"VersionNumber"]]) {
            [[NSUserDefaults standardUserDefaults] setValue:@"2" forKey:@"VersionNumber"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        
            _username = username;
            [self pathInitialization];
            _sendingView = sendingView;
            
            NSLog(@"migration happening...");
            
            //if (_filenames.count>0) [self handleMigration];
            
        }
    }
    return self;
}

- (void) pathInitialization
{
    _paths = [[NSArray alloc] initWithArray:[self newArrayWithFolders:_username]];
    _userDictionary = [[NSMutableDictionary alloc]initWithContentsOfFile:[[_paths objectAtIndex:USER] stringByAppendingFormat:@"/%@.plist",_username]];
    _filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_paths objectAtIndex:IMAGES] error:NULL];
    
    _serverConnection = [[ServerConnection alloc] init];
    _serverConnection.delegate = self;
}



#pragma mark -
#pragma mark Main methods

- (void) handleMigration
{
    [_sendingView.textView setText:@"Upgrading..." ];
    [_sendingView setNeedsDisplay];
    [self sendInfoToTheServer];
    [self resetFilesystem];
}


- (void) sendInfoToTheServer
{
    
    //Get the sending state and send the necessary ones
    for (NSString *filename in _filenames) {
        int state = [[_userDictionary objectForKey:filename] intValue];
        
        NSMutableArray *boxes = [self boxesForFilename:filename];
        UIImage *image = [self imageForFilename:filename];
        
        double f = image.size.height/image.size.width;
        Box *box;
        CGPoint point;
        if(boxes.count > 0) {
            box = [boxes objectAtIndex:0];
            point = f>1 ? CGPointMake(image.size.height/(box.imageSize.width*f), image.size.height/box.imageSize.height) : CGPointMake(image.size.width/(box.imageSize.width), image.size.width*f/(box.imageSize.height));
        }
        
        [_sendingView.progressView setProgress:0];
        if (state < 0) {
            NSLog(@"Image %@ with state %d needs to be sent", filename, state);
            NSString *boxPath = [[_paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
            [_serverConnection sendPhoto:image filename:filename path:boxPath withSize:point andAnnotation:boxes];
        }else if (state > 0){
            NSLog(@"Image %@ with state %d needs to be updated", filename, state);
            [_serverConnection updateAnnotationFrom:filename withSize:point :boxes];
        }
    }
}

- (void) resetFilesystem
{
    
}



#pragma mark -
#pragma mark ServerConnectionDelegate

-(void)photoSentCorrectly:(NSString *)filename
{
}



#pragma mark -
#pragma mark Private methods

- (NSMutableArray *) boxesForFilename:(NSString *) filename
{
    
    NSString *boxesPath = [[_paths objectAtIndex:OBJECTS] stringByAppendingPathComponent:filename];
    NSMutableArray *boxes = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:boxesPath]];
    return boxes;
}

- (UIImage *) imageForFilename:(NSString *) filename
{
    NSString *imagePath = [[_paths objectAtIndex:IMAGES] stringByAppendingPathComponent:filename];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    return image;
}

@end
