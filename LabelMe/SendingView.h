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
@interface SendingView : UIView{
    
    UIProgressView *_progressView;
    UIActivityIndicatorView *_activityIndicator;
    UILabel *_label;
    NSString *_filename;
    UIButton *_cancelButton;
    int total;
    int num;
    
}
@property (nonatomic, assign) id <SendingViewDelegate> delegate;

@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) UILabel *label;
@property (nonatomic, retain) UIButton *cancelButton;

@property (nonatomic, retain) NSString *filename;

-(void)setTotal:(int) i;
-(void)incrementNum;
-(void)reset;
@end
