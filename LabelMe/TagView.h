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

-(void)objectModified; //saving purposes


@end


@interface TagView : UIView

// Responsible to handle when the box has been modified
@property (nonatomic, weak) id <TagViewDelegate> delegate;
@property (nonatomic, strong) UITextField* label;
@property (nonatomic, strong) NSArray* boxes;

// Index of the selected box
@property int selectedBox;

// When the superview performs a zoom through UIScrollView
- (void) setLineWidthForZoomFactor:(float)factor;

//labelHandling
- (IBAction)labelFinish:(id)sender;

- (void) addBox:(Box *)box;
- (void) deleteSelectedBox;

@end
