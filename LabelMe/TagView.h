//
//  TagView.h
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Box.h"


@protocol TagViewDelegate <NSObject>

@optional
-(void)objectModified; //saving purposes
-(void)selectedAnObject:(BOOL)value;

@end


@interface TagView : UIView

@property (nonatomic, weak) id <TagViewDelegate> delegate;
@property (nonatomic, strong) UITextField* label;
@property (nonatomic, strong) NSMutableArray* boxes;
@property (nonatomic, strong) NSString* filename; //Image filename
@property int selectedBox;

//restarts
- (void) setLineWidthForZoomFactor:(float)factor;

//labelHandling
- (IBAction)labelFinish:(id)sender;

@end
