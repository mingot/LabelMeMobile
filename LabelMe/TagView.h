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
-(void)selectedAnObject:(BOOL)value;

@end


@interface TagView : UIView

// Responsible to handle when the box has been modified
@property (nonatomic, weak) id <TagViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray* boxes;
@property (nonatomic, strong) UITextField* label;

// Index of the selected box
@property int selectedBox;



// When the superview performs a zoom through UIScrollView
- (void) setLineWidthForZoomFactor:(float)factor;

//labelHandling
- (IBAction)labelFinish:(id)sender;

@end
