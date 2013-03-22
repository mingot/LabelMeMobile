//
//  ServerConnection.h
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
@protocol ServerConnectionDelegate <NSObject>

@optional
-(void)signInComplete;
-(void)signInWithoutConnection;
-(void)signInError;
-(void)createAccountComplete;
-(void)createAccountError;
-(void)sendingProgress:(float)prog;
-(void)photoSentCorrectly:(NSString *)filename;
-(void)sendPhotoError;
-(void)photoNotOnServer:(NSString *)filename;
-(void)profilePictureReceived:(UIImage *)ppicture;

@end
@interface ServerConnection : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>{
    
    //NSURLConnection             * _loginConnection;
    NSString                    * _checkLoginURL;
   // NSURLConnection             * _createAccountConnection;
    NSString                    * _createAccountURL;
   // NSURLConnection             * _sendPhotoConnection;
    NSString                    * _sendPhotoURL;
    NSString                    * _updateAnnotationURL;
    NSString                    * _downloadProfilePictureURL;
    NSString                    * _uploadProfilePictureURL;
    NSString                    * _forgotPasswordURL;


   // NSURLConnection             * _profilePictureConnection;

    NSMutableData               * receivedData;
    float                       bytestowrite;
    NSString                    *_filenamePending;
    BOOL                        cancel;

}



@property (nonatomic, weak) id <ServerConnectionDelegate> delegate;
//@property (nonatomic, retain) NSURLConnection   *loginConnection;
@property (nonatomic, strong) NSString          *checkLoginURL;
//@property (nonatomic, retain) NSURLConnection   *createAccountConnection;
@property (nonatomic, strong) NSString          *createAccountURL;
//@property (nonatomic, retain) NSURLConnection   *sendPhotoConnection;
@property (nonatomic, strong) NSString          *sendPhotoURL;
@property (nonatomic, strong) NSString          *updateAnnotationURL;
@property (nonatomic, strong) NSString          *downloadProfilePictureURL;
@property (nonatomic, strong) NSString          *uploadProfilePictureURL;
@property (nonatomic, strong) NSString          *forgotPasswordURL;

//@property (nonatomic, retain) NSURLConnection   *profilePictureConnection;

@property (nonatomic, strong) NSString          *filenamePending;

-(void)setURLs;
-(void)checkLoginForUsername:(NSString *)username andPassword:(NSString *)password;
-(void)createAccountWithFields:(NSArray *)fields;
-(void)forgotPassword:(NSString *)email;
-(void)sendPhoto:(UIImage *) photo filename: (NSString *)filename path:(NSString *)objectpath withSize:(CGPoint)size andAnnotation:(NSMutableArray *) annotation;
-(void)updateAnnotationFrom: (NSString *)filename withSize:(CGPoint) size: (NSMutableArray *) annotation;
-(void)downloadProfilePictureToUsername:(NSString *) username;
-(void)uploadProfilePicture:(UIImage *)ppicture;
-(void)cancelRequestFor:(int)req;
@end
