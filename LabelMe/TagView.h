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
-(void)objectModified;
-(void)selectedAnObject:(BOOL)value;
-(void)hiddenTextField:(BOOL)value;
-(void)stringLabel:(NSString *)string;
-(void)correctOrientation:(CGPoint)upperLeft : (CGPoint)lowerRight SuperviewFrame:(CGRect)viewSize;

@end


@interface TagView : UIView
{
    CGPoint firstLocation;
    
    int selectedBox;
    int corner;
    BOOL move;
    BOOL size;
    
    float UPPERBOUND;
    float LOWERBOUND;
    float LEFTBOUND;
    float RIGHTBOUND;
    float lineOriginal;
    float LINEWIDTH;
    CGRect visibleFrame;

}
@property (nonatomic, weak) id <TagViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) NSArray *colorArray;



- (void) setSelectedBox:(int) i;
- (int) SelectedBox;
- (void) drawBox:(CGContextRef )context :(Box *)box1 :(CGFloat)alpha;
- (void) drawSelectedBox:(CGContextRef )context :(Box *) box;
- (void) reset;
- (void)setLINEWIDTH:(float)factor;
- (int)whereIs:(CGPoint) point;
- (int)boxInterior:(int)i :(CGPoint)point;
- (void)setVisibleFrame:(CGRect)rect;
- (CGRect)visibleFrame;
- (BOOL) anyBoxSelected;

@end
