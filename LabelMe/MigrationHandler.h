//
//  MigrationHandler.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 14/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerConnection.h"
#import "SendingView.h"


/*
 
 Class  Responsibilities:
 
 - Send all the boxes and images not send to the server.
 - Delete the whole current Filesystem to provide a fresh start.
 - Show Sending View Informing of the process
 
 
 */
@interface MigrationHandler : NSObject <ServerConnectionDelegate>

- (id)initWithUsername:(NSString *) username withSendingView:(SendingView *)sendingView;

@end
