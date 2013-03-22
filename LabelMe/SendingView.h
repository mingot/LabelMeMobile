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
@property (nonatomic, weak) id <SendingViewDelegate> delegate;

@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, strong) NSString *filename;

-(void)setTotal:(int) i;
-(void)incrementNum;
-(void)reset;
@end
