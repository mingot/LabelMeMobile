//
//  ServerConnection.m
//  LabelMe
//
//  Created by Dolores on 26/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "ServerConnection.h"
#import "NSObject+ShowAlert.h"
#import "Box.h"
#import "NSObject+Folders.h"


@implementation ServerConnection
//@synthesize loginConnection = _loginConnection;
@synthesize checkLoginURL = _checkLoginURL;
//@synthesize createAccountConnection = _createAccountConnection;
@synthesize createAccountURL = _createAccountURL;
@synthesize updateAnnotationURL = _updateAnnotationURL;
//@synthesize sendPhotoConnection = _sendPhotoConnection;
@synthesize sendPhotoURL = _sendPhotoURL;
@synthesize downloadProfilePictureURL = _downloadProfilePictureURL;
@synthesize uploadProfilePictureURL = _uploadProfilePictureURL;
@synthesize forgotPasswordURL = _forgotPasswordURL;
//@synthesize profilePictureConnection = _profilePictureConnection;




static UIImage* rotate(UIImage* src, UIImageOrientation orientation)
{
    UIGraphicsBeginImageContext(src.size);
    [src drawAtPoint:CGPointMake(0, 0)];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, M_PI/2);
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, (-M_PI/2));
    } else if (orientation == UIImageOrientationDown) {
        CGContextRotateCTM (context, (-M_PI));
    } else if (orientation == UIImageOrientationUp) {
        // NOTHING
    }
    /* CGContextDrawImage(UIGraphicsGetCurrentContext(),
     CGRectMake(0,0,src.size.width, src.size.height),
     src.CGImage);*/
    /*UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();*/
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
static BOOL didSignIn = NO;
#pragma mark -
#pragma mark Initialization Methods
-(id)init{
    self = [super init];
    if (self) {
        [self setURLs];
        cancel = NO;
        receivedData = [[NSMutableData alloc]init];
        self.filenamePending = [[NSString alloc]init];
    }
    return self;
}
-(void)setURLs{
    
    /*self.checkLoginURL = [[NSString alloc]initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/checkLoginFromiPhone.php"];
    self.createAccountURL = [[NSString alloc]initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/addUserFromiPhone2.php"];
    self.sendPhotoURL = [[NSString alloc] initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/sendPhotoFromiPhone.php"];
    self.updateAnnotationURL = [[NSString alloc] initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/updateAnnotation.php"];
    self.downloadProfilePictureURL = [[NSString alloc] initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/downloadProfilePicture.php"];
    self.uploadProfilePictureURL = [[NSString alloc] initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/uploadProfilePicture.php"];
    self.forgotPasswordURL = [[NSString alloc] initWithString:@"http://labelme2.csail.mit.edu/developers/dolores/LabelMe3.0/iphoneAppTools/forgot_password.php"];*/
    self.checkLoginURL = [[NSString alloc]initWithString:@"http://labelme.csail.mit.edu/Release3.0/iphoneAppTools/checkLoginFromiPhone.php"];
    self.createAccountURL = [[NSString alloc]initWithString:@"http://labelme.csail.mit.edu/Release3.0/iphoneAppTools/addUserFromiPhone2.php"];
    self.sendPhotoURL = [[NSString alloc] initWithString:@"http://labelme.csail.mit.edu/Release3.0/iphoneAppTools/sendPhotoFromiPhone.php"];
    self.updateAnnotationURL = [[NSString alloc] initWithString:@"http://labelme.csail.mit.edu/Release3.0/iphoneAppTools/updateAnnotation.php"];
    self.downloadProfilePictureURL = [[NSString alloc] initWithString:@"http://labelme.csail.mit.edu/Release3.0/iphoneAppTools/downloadProfilePicture.php"];
    self.uploadProfilePictureURL = [[NSString alloc] initWithString:@"http://labelme.csail.mit.edu/Release3.0/iphoneAppTools/uploadProfilePicture.php"];
    self.forgotPasswordURL = [[NSString alloc] initWithString:@"http://labelme.csail.mit.edu/Release3.0/browserTools/php/forgot_password.php"];


}
#pragma mark -
#pragma mark Request Methods

-(void)checkLoginForUsername:(NSString *)username andPassword:(NSString *)password{
    didSignIn = NO;
    
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.checkLoginURL]];
    
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [[NSString alloc] initWithFormat:@"multipart/form-data, boundary=%@", boundary ];
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [[NSMutableData alloc]init];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [theRequest setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }

    [boundary release];
    [theRequest release];
    [contentType release];
    [postBody release];
    
    //[NSURLConnection connectionWithRequest:theRequest delegate:self];
}
-(void) createAccountWithFields:(NSArray *)fields{
    NSString *name = [fields objectAtIndex:0];
    NSString *institution = [fields objectAtIndex:1];
    NSString *username = [fields objectAtIndex:2];
    NSString *password = [fields objectAtIndex:3];
    NSString *email = [fields objectAtIndex:4];
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.createAccountURL]];
    
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [[NSString alloc] initWithFormat:@"multipart/form-data, boundary=%@", boundary ];
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [[NSMutableData alloc]init];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"name\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[name dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"institution\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[institution dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[password dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"email\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[email dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [theRequest setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }
    [boundary release];
    [theRequest release];
    [contentType release];
    [postBody release];
    
}
-(void)forgotPassword:(NSString *)email{
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.forgotPasswordURL]];
    
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [[NSString alloc] initWithFormat:@"multipart/form-data, boundary=%@", boundary ];
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [[NSMutableData alloc]init];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"email\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[email dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [theRequest setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
    }
    
    [boundary release];
    [theRequest release];
    [contentType release];
    [postBody release];
}
-(void)sendPhoto:(UIImage *) photo filename: (NSString *)filename path:(NSString *)objectpath withSize:(CGPoint)size andAnnotation:(NSMutableArray *) annotation{
    cancel = NO;

    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[objectpath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *dictnum = [dict objectForKey:@"wifi"];
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (dictnum.boolValue) {
        
        if ((networkStatus != ReachableViaWiFi) && (networkStatus !=NotReachable)) {
            [self errorWithTitle:@"Check your connection" andDescription:@"Sorry, wifi connection is required."];
            [self.delegate sendPhotoError];
            [dict release];
            return;
        }
    }
    if (!didSignIn) {
        NSArray *fields = [[NSArray alloc] initWithArray:[self signInAgain]];
        [self createHTTPBodyWithImage:photo size:size filename:filename path:objectpath andAnnotation:annotation];
        self.filenamePending = filename;
        NSString *user = [[NSString alloc] initWithData:[fields objectAtIndex:0] encoding:NSUTF8StringEncoding];
        NSString *pass = [[NSString alloc] initWithData:[fields objectAtIndex:1] encoding:NSUTF8StringEncoding];

        [self checkLoginForUsername:user andPassword:pass];
        [user release];
        [pass release];
        [fields release];
        return;
    }
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.sendPhotoURL]];
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
    
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    [self createHTTPBodyWithImage:photo size:size filename:filename path:objectpath andAnnotation:annotation];
   // NSArray *arr = [NSArray arrayWithObjects:photo,[NSNumber numberWithFloat:size.x],[NSNumber numberWithFloat:size.y],filename,objectpath,annotation,fields,nil];
   // [self performSelectorInBackground:@selector(createBodyWithArray:) withObject:arr];
    
    NSFileManager * filemng = [NSFileManager defaultManager];
    
    //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(nstem, NSUserDomainMask, YES) objectAtIndex:0];
   // NSString *tmpPath = [documentsDirectory stringByAppendingPathComponent:@"tmpRequest"];
    NSString *tmpPath = NSTemporaryDirectory();
    //NSInputStream *bodyStream = [NSInputStream inputStreamWithFileAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]]];
    NSInputStream *bodyStream = [[NSInputStream alloc] initWithFileAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]]];
    [theRequest setHTTPBodyStream:bodyStream];
    NSNumber *filesize = [[filemng attributesOfItemAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] error:nil] objectForKey:NSFileSize];
    bytestowrite = [filesize doubleValue];
    //[theRequest setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }
    self.filenamePending = @"";
    [boundary release];
    [theRequest release];
    [bodyStream release];
    
}
-(void)sendPhotoWithFilename:(NSString *)filename{
    cancel = NO;

    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.sendPhotoURL]];
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
    
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSFileManager * filemng = [NSFileManager defaultManager];
    
    //NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(nstem, NSUserDomainMask, YES) objectAtIndex:0];
    // NSString *tmpPath = [documentsDirectory stringByAppendingPathComponent:@"tmpRequest"];
    NSString *tmpPath = NSTemporaryDirectory();
    //NSInputStream *bodyStream = [NSInputStream inputStreamWithFileAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]]];
    NSInputStream *bodyStream = [[NSInputStream alloc] initWithFileAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]]];
    [theRequest setHTTPBodyStream:bodyStream];
    NSNumber *filesize = [[filemng attributesOfItemAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] error:nil] objectForKey:NSFileSize];
    bytestowrite = [filesize doubleValue];
    //[theRequest setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }
    self.filenamePending = @"";
    [boundary release];
    [theRequest release];
    [bodyStream release];

}
/*-(void)createBodyWithArray:(NSArray *)info{
    if(info.count == 7){
        NSNumber *x = [info objectAtIndex:1];
        NSNumber *y = [info objectAtIndex:2];

        [self createHTTPBodyWithImage:[info objectAtIndex:0] size:CGPointMake(x.floatValue, y.floatValue) filename:[info objectAtIndex:3] path:[info objectAtIndex:4] andAnnotation:[info objectAtIndex:5] andFields:[info objectAtIndex:6]];
    }
}*/
-(void)updateAnnotationFrom: (NSString *)filename withSize:(CGPoint) size: (NSMutableArray *) annotation{
    // [self.delegateProgress startProgress];
    //Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
   // NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    cancel = NO;

    
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.updateAnnotationURL]];
    NSData *annotationData = [[NSData alloc]initWithData:[self createXMLFromAnnotation:annotation andImageSize:size]];
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [[NSMutableData alloc] init];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"filename\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[filename dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"annotation\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:annotationData];
   /* [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[fields objectAtIndex:0]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[fields objectAtIndex:1]];*/

    
    
    /*[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
     [postBody appendData:[@"Content-Disposition: hidden; name=\"MAX_FILE_SIZE\"value=\"12000000\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];*/
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    if (!didSignIn) {
        NSArray *fields = [[NSArray alloc] initWithArray:[self signInAgain]];
        self.filenamePending = [NSString stringWithFormat:@"%@_update2278965",filename];
        NSString *user = [[NSString alloc] initWithData:[fields objectAtIndex:0] encoding:NSUTF8StringEncoding];
        NSString *pass = [[NSString alloc] initWithData:[fields objectAtIndex:1] encoding:NSUTF8StringEncoding];
        NSString *tmpPath = NSTemporaryDirectory();
        NSString *path = [[NSString alloc] initWithFormat:@"%@/%@",tmpPath,self.filenamePending ];
        [postBody writeToFile:path atomically:YES];
        [self checkLoginForUsername:user andPassword:pass];
        [path release];
        [user release];
        [pass release];
        [fields release];
        [boundary release];
        [theRequest release];
        [postBody release];
        return;
    }
    [theRequest setHTTPBody:postBody];
    bytestowrite = [postBody length];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }self.filenamePending = @"";
    [boundary release];
    [theRequest release];
    [postBody release];
}
-(BOOL)createHTTPBodyWithImage: (UIImage *)image size:(CGPoint)point filename:(NSString *)filename  path:(NSString *)objectpath andAnnotation:(NSMutableArray *)annotation{
    BOOL ret= NO;
    NSFileManager * filemng = [NSFileManager defaultManager];
   // NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    BOOL isDir = YES;
    //NSString *tmpPath = [documentsDirectory stringByAppendingPathComponent:@"tmpRequest"];
    NSString *tmpPath = NSTemporaryDirectory();

    if (![filemng fileExistsAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] isDirectory:&isDir]) {
        NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
        UIImage *imageToSend = rotate(image, image.imageOrientation);
        NSData *imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(imageToSend, 1.0)];
        NSData *annotationData = [[NSData alloc] initWithData:[self createXMLFromAnnotation:annotation andImageSize:point]];
        NSString *location = [[NSString alloc] initWithContentsOfFile:[objectpath stringByAppendingPathComponent:[[filename stringByDeletingPathExtension] stringByAppendingString:@".txt"] ] encoding:NSUTF8StringEncoding error:NULL];
        NSMutableData *postBody = [[NSMutableData alloc] init];
        [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image_file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Type: image/jpeg \r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:imageData];
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Disposition: form-data; name=\"annotation\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:annotationData];
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[@"Content-Disposition: form-data; name=\"location\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        [postBody appendData:[location dataUsingEncoding:NSUTF8StringEncoding]];
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        if([postBody writeToFile:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] atomically:NO]){
            ret = YES;
        }
        [boundary release];
        [imageData release];
        [annotationData release];
        [postBody release];
        [location release];
        
    }
    return ret;
    
}
-(void)updateAnnotationWithFilename:(NSString *)filename{
    cancel = NO;

    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.updateAnnotationURL]];
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
    
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSFileManager * filemng = [NSFileManager defaultManager];
    
    NSString *tmpPath = NSTemporaryDirectory();
    NSInputStream *bodyStream = [[NSInputStream alloc] initWithFileAtPath:[tmpPath stringByAppendingPathComponent:filename]];
    [theRequest setHTTPBodyStream:bodyStream];
    NSNumber *filesize = [[filemng attributesOfItemAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] error:nil] objectForKey:NSFileSize];
    bytestowrite = [filesize doubleValue];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }
    self.filenamePending = @"";
    [boundary release];
    [theRequest release];
    [bodyStream release];

}
-(NSString *)generateDateString{
    NSString *originalDate = [[[NSDate date] description] substringToIndex:19];
    NSString *time = [originalDate substringFromIndex:11];
    NSString *day = [originalDate substringWithRange:NSMakeRange(8, 2)];
    NSString *year = [originalDate substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [originalDate substringWithRange:NSMakeRange(5, 2)];
    int m = [month intValue];
    switch (m) {
        case 1:
            month = @"Jan";
            break;
        case 2:
            month = @"Feb";
            break;
        case 3:
            month = @"Mar";
            break;
        case 4:
            month = @"Apr";
            break;
        case 5:
            month = @"May";
            break;
        case 6:
            month = @"Jun";
            break;
        case 7:
            month = @"Jul";
            break;
        case 8:
            month = @"Aug";
            break;
        case 9:
            month = @"Sep";
            break;
        case 10:
            month = @"Oct";
            break;
        case 11:
            month = @"Nov";
            break;
        case 12:
            month = @"Dec";
            break;
        default:
            break;
    }
    NSString *ret = [NSString stringWithFormat:@"%@-%@-%@ -%@",day,month,year,time];
    return ret;
    
}

-(NSData *)createXMLFromAnnotation:(NSMutableArray *) annotation andImageSize:(CGPoint) point{
    NSMutableData *XMLString = [[[NSMutableData alloc] init] autorelease];
    NSString *boundary = [[NSString alloc]initWithString:@"--022289--"];
        for (int i=0; i<annotation.count; i++) {

            Box *b = [annotation objectAtIndex:i];
            int x1 = (int) (b.upperLeft.x*point.x);
            int x2 = (int) (b.lowerRight.x*point.x);
            int x3 = (int) (b.lowerRight.x*point.x);
            int x4 = (int) (b.upperLeft.x*point.x);
            int y1 = (int) (b.upperLeft.y*point.y);
            int y2 = (int) (b.upperLeft.y*point.y);
            int y3 = (int) (b.lowerRight.y*point.y);
            int y4 = (int) (b.lowerRight.y*point.y);
            if (i == annotation.count-1) {

                NSString *object = [NSString stringWithFormat:@"%@%@%@%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d",b.label,boundary,b.date,boundary,i,boundary,x1,boundary,y1,boundary,x2,boundary,y2,boundary,x3,boundary,y3,boundary,x4,boundary,y4,boundary,x1,boundary,y1];
                [XMLString appendData:[object dataUsingEncoding:NSUTF8StringEncoding]];
                break;

            }
            NSString *object = [NSString stringWithFormat:@"%@%@%@%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@%d%@",b.label,boundary,b.date,boundary,i,boundary,x1,boundary,y1,boundary,x2,boundary,y2,boundary,x3,boundary,y3,boundary,x4,boundary,y4,boundary,x1,boundary,y1,boundary];
            [XMLString appendData:[object dataUsingEncoding:NSUTF8StringEncoding]];
        }
    
    
    [boundary release];
    return XMLString;
}
-(void)downloadProfilePictureToUsername:(NSString *) username{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:username] stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *dictnum = [dict objectForKey:@"wifi"];
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (dictnum.boolValue) {
        
        if ((networkStatus != ReachableViaWiFi) && (networkStatus !=NotReachable)) {
            return;
        }
    }
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.downloadProfilePictureURL]];
    [theRequest setHTTPMethod:@"POST"];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }
    [theRequest release];
}
-(void)uploadProfilePicture:(UIImage *)ppicture{
    NSArray *fields = [[NSArray alloc] initWithArray:[self signInAgain]];
    
    
    NSString *boundary = [[NSString alloc]initWithString:@"AaB03x"];
    UIImage *imageToSend = rotate(ppicture, ppicture.imageOrientation);
    NSData *imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(imageToSend, 1.0)];
    NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.uploadProfilePictureURL]];
    [theRequest setHTTPMethod:@"POST"];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", boundary];
    [theRequest setValue:contentType forHTTPHeaderField:@"Content-type"];
    NSMutableData *postBody = [[NSMutableData alloc] init];
    [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"image_file\"; filename=\"%@\"\r\n", @"profilepicture.jpg"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Type: image/jpeg \r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:imageData];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"username\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[fields objectAtIndex:0]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[@"Content-Disposition: form-data; name=\"password\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[fields objectAtIndex:1]];
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r \n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [theRequest setHTTPBody:postBody];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
    if (connection == nil) {
        [self errorWithTitle:@"Unknown error" andDescription:@""];
    }
    else{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    }
    [boundary release];
    [theRequest release];
    [postBody release];
    [imageData release];

}
-(NSArray *) signInAgain{
    
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSError *error;
    BOOL isDir = NO;
    NSString *username = nil;
    NSString *password = nil;

    if ([filemng fileExistsAtPath:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"]  isDirectory:&isDir]) {
        username= [NSString stringWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"username.txt"]  encoding:NSUTF8StringEncoding error:&error];
        
            if ([filemng fileExistsAtPath:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"]  isDirectory:&isDir]) {
                password = [NSString stringWithContentsOfFile:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"]  encoding:NSUTF8StringEncoding error:&error];
            }
            
    }

    /* [username release];
    [password release];*/
    return [NSArray arrayWithObjects:[username dataUsingEncoding:NSUTF8StringEncoding],[password dataUsingEncoding:NSUTF8StringEncoding], nil];

}
#pragma mark -
#pragma mark NSURLConnectionDelegate Methods
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
     if (cancel) {

        [connection cancel];
        [connection release];
        cancel = NO;
    }
    [receivedData appendData:data];

}
-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    if (cancel) {
        [connection cancel];
        [connection release];
        cancel = NO;
    }
    if ([connection.currentRequest.URL.absoluteString isEqualToString:self.sendPhotoURL] || [connection.currentRequest.URL.absoluteString isEqualToString:self.updateAnnotationURL]) {
        float p = (float) totalBytesWritten / (float) bytestowrite ;
        if ([self.delegate respondsToSelector:@selector(sendingProgress:)]) {
            [self.delegate sendingProgress:p];
        }

    }

}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if([connection.currentRequest.URL.absoluteString isEqualToString:self.checkLoginURL]){
        if ([self.delegate respondsToSelector:@selector(signInWithoutConnection)]) {
            [self.delegate signInWithoutConnection];
        }
        else if ([self.delegate respondsToSelector:@selector(sendPhotoError)]) {
            [self.delegate sendPhotoError];
        }
    }
    else if([connection.currentRequest.URL.absoluteString isEqualToString:self.createAccountURL]){
        [self errorWithTitle:error.localizedDescription andDescription:error.localizedRecoverySuggestion];
        [self.delegate createAccountError];

    }
    else if([connection.currentRequest.URL.absoluteString isEqualToString:self.sendPhotoURL] || [connection.currentRequest.URL.absoluteString isEqualToString:self.updateAnnotationURL]){
       // [self.delegate createAccountError];
        if ([self.delegate respondsToSelector:@selector(sendPhotoError)]) {
            [self.delegate sendPhotoError];
        }
        else{
            [self errorWithTitle:error.localizedDescription andDescription:error.localizedRecoverySuggestion];

        }
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [connection release]; // no se si deberia ir aqui
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    if ([connection.currentRequest.URL.absoluteString isEqualToString:self.checkLoginURL]) {
        NSString *response = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSArray *divided = [[NSArray alloc] initWithArray:[response componentsSeparatedByString:@"\n"]];
        int result = [[divided objectAtIndex:divided.count -2] integerValue];
        switch (result) {
                
            case 0:
                didSignIn = YES;
                if (self.filenamePending.length > 0) {
                    if ([[self.filenamePending substringFromIndex:self.filenamePending.length - 14] isEqualToString:@"_update2278965"]) {
                        [self updateAnnotationWithFilename:self.filenamePending];
                    }
                    else{
                        [self sendPhotoWithFilename:self.filenamePending];
                    }
                }
                if ([self.delegate respondsToSelector:@selector(signInComplete)]) {
                    [self.delegate signInComplete];
                }

                break;
                
            default:
                [self errorWithTitle:@"We did not recognise your username and password" andDescription:@"Please, try again."];
                [self.delegate signInError];
                break;
                
        }
        [response release];
        [divided release];
    }
    else if ([connection.currentRequest.URL.absoluteString isEqualToString:self.createAccountURL]) {
        NSString *response = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];

        NSArray *divided = [[NSArray alloc] initWithArray:[response componentsSeparatedByString:@"\n"]];
        int result = [[divided objectAtIndex:divided.count -2] integerValue];
        switch (result) {
                
            case 0:
                [self.delegate createAccountComplete];
                break;
                
            default:
                [self errorWithTitle:[divided objectAtIndex:divided.count-1] andDescription:@"Please, try again."];
                break;
                
        }
        [response release];
        [divided release];
        
    }
    else if ([connection.currentRequest.URL.absoluteString isEqualToString:self.sendPhotoURL] || [connection.currentRequest.URL.absoluteString isEqualToString:self.updateAnnotationURL]){
        
        NSString *result = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSArray *divided = [[NSArray alloc] initWithArray:[result componentsSeparatedByString:@"\n"]];
        NSString *value = [divided objectAtIndex:divided.count-2];
        int resultCode = [value integerValue];
        NSFileManager * filemng = [NSFileManager defaultManager];
        NSString *filename = [divided lastObject];
        NSString *tmpPath = NSTemporaryDirectory();


        switch (resultCode) {
            case 0:
                [filemng removeItemAtPath:[tmpPath stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] error:NULL];
                [self.delegate photoSentCorrectly:filename];
                break;
            case 2:
                //[self errorWithTitle:@"ERROR" andDescription:[divided objectAtIndex:divided.count-1]];
                [self.delegate photoNotOnServer:[divided objectAtIndex:divided.count-3]];
                break;
            default:
                [self errorWithTitle:[divided objectAtIndex:divided.count-1] andDescription:@"Please, try again."];
                [self.delegate sendPhotoError];
                break;
        }

        [result release];
        [divided release];
       // [self.delegate photoSentCorrectly:filename];
        
    }
    else if ([connection.currentRequest.URL.absoluteString isEqualToString:self.downloadProfilePictureURL] || [connection.currentRequest.URL.absoluteString isEqualToString:self.uploadProfilePictureURL]){
        //NSString *response = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];
        if (receivedData.length > 8) {
            if ([self.delegate respondsToSelector:@selector(profilePictureReceived:)]) {
                [self.delegate profilePictureReceived:[UIImage imageWithData:receivedData]];

            }
            else{
                if ([self.delegate respondsToSelector:@selector(profilePictureReceived:)]) {
                    [self.delegate profilePictureReceived:nil];

                }
            }

        }
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [connection release];
    [receivedData setLength:0];

}
-(void)cancelRequestFor:(int)req{
    cancel = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    
}


#pragma mark -
#pragma mark Memory Management

-(void)dealloc{
    [self.checkLoginURL release];
    [receivedData  release];
    [self.createAccountURL release];
    [self.sendPhotoURL release];
    [self.filenamePending release];
    [super dealloc];
}

@end
