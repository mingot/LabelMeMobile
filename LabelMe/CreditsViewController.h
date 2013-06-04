//
//  CreditsViewController.h
//  LabelMe
//
//  Created by Dolores on 20/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreditsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *titleView;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@end
