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
{
    int total;
    int num;
}


@property (nonatomic, weak) id <SendingViewDelegate> delegate;

@property (strong, nonatomic)  UIProgressView *progressView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UITextView *textView;

@property (nonatomic, strong) NSString *filename;





-(void)setTotal:(int) i;
-(void)incrementNum;
-(void)reset;
-(void)showMessage:(NSString *)message;
-(void)clearScreen;

- (IBAction)cancelAction:(id)sender;

@end
