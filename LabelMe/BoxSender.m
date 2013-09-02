//
//  BoxSender.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 01/09/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "BoxSender.h"
#import "BoundingBox.h"
#import "SocketIO.h"
#import "SocketIOPacket.h"


@interface BoxSender() <SocketIODelegate>
{
    SocketIO *_socketIO;
    int _counter;
}

- (void)_reconnect;

@end

@implementation BoxSender

#pragma mark -
#pragma mark Initialization

- (id)init
{
    
    if (self = [super init]) {
        _counter = 0;
    }
    return self;
}

- (void)_reconnect
{    
    _socketIO = [[SocketIO alloc] initWithDelegate:self];
    [_socketIO connectToHost:@"128.31.33.201" onPort:7000];
}


- (void) dealloc
{
    [self closeConnection];
}


#pragma mark -
#pragma mark Public methods


- (void) openConnection
{
    [self _reconnect];
}

- (void) closeConnection
{    
    [_socketIO disconnect];
}

- (void) sendBoxes:(NSArray *)boxes
{
    
    NSMutableDictionary *boxDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    for(NSArray *detectorBoxes in boxes)
        for(BoundingBox *box in detectorBoxes){
            [boxDictionary setObject:[NSString stringWithFormat:@"%f", (box.xmin + box.xmax)/2] forKey:@"xcoord"];
            [boxDictionary setObject:[NSString stringWithFormat:@"%f", (box.ymin + box.ymax)/2] forKey:@"ycoord"];
            [_socketIO sendEvent:@"emit_bb" withData:boxDictionary];
            _counter ++;
        }
}


#pragma mark -
#pragma mark SocketIO Delegate


- (void) socketIODidConnect:(SocketIO *)socket
{
    NSLog(@"[socketIO] connected");
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error
{
    NSLog(@"[socketIO] disconnected");
}

- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet
{
    NSLog(@"[socketIO] message sent");
}

- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet
{
    NSLog(@"[socketIO] didReceiveMessage() >>> data: %@", packet.data);
}


@end
