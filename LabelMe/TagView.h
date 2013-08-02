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


// send when and object is: moved, resized or changed the label
- (void)objectModified;

@end


@interface TagView : UIView <UITextFieldDelegate>

// Responsible to handle when the box has been modified
@property (nonatomic, weak) id <TagViewDelegate> delegate;
@property (nonatomic, strong) UITextField* label;
@property (nonatomic, strong) NSArray* boxes;

// Index of the selected box
@property int selectedBox;

// Returns nil if no box selected
- (Box *) getSelectedBox;

// When the superview performs a zoom through UIScrollView
// Redraws at the correct size the lines width and the labels
- (void) setUpViewForZoomScale:(float)factor;

//labelHandling
- (IBAction)labelFinish:(id)sender;

// Draws and adds the given box
- (void) addBox:(Box *)box;

// Create a random box in a visible rect
// Needed when zoom is in to know where to put the initial points of the box
- (void) addBoxInVisibleRect:(CGRect)visibleRect;

// If anyboxselected, it removes it
- (void) removeSelectedBox;


@end
