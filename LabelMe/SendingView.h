//
//  SendingView.h
//  LabelMe
//
//  Created by Dolores on 02/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SendingViewDelegate <NSObject>

@optional
-(void)cancel;

@end



@interface SendingView : UIView

//view
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (strong, nonatomic) NSString *sendingViewID; //to identify
@property (nonatomic, weak) id <SendingViewDelegate> delegate;

-(void)setTotal:(int) i;
-(void)incrementNum;

-(void)reset;
-(void)showMessage:(NSString *)message;
-(void)clearScreen;

- (IBAction)cancelAction:(id)sender;

@end
