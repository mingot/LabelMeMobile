//
//  CreditsViewController.h
//  LabelMe
//
//  Created by Dolores on 20/11/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreditsViewController : UIViewController{
    UIScrollView *_scrollView;
}
@property (nonatomic,retain) IBOutlet UIScrollView *scrollView;
@end
