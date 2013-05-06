//
//  LogVC.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 02/05/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import<UIKit/UIKit.h>

@protocol LogVCDelegate <NSObject>


- (void) cancelLogVC;

@end


@interface LogVC : UIViewController

@property (strong, nonatomic) id<LogVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (strong, nonatomic) NSMutableArray *messagesStack;

- (IBAction)cancelAction:(id)sender;
-(void)showMessage:(NSString *)message;

@end
