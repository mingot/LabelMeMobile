//
//  BoxSender.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 01/09/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 
 Class  Responsibilities:
 
 - Manage WebSocket connection with the server
 - Send boxes to it
 
 
 */
@interface BoxSender : NSObject 


- (void) sendBoxes:(NSArray *)boxes;
- (void) openConnection;
- (void) closeConnection;

@end
