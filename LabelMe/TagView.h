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
-(void)correctOrientationForBox:(Box *)box SuperviewFrame:(CGRect)viewSize;

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
}

@property (nonatomic, weak) id <TagViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *boxes;
@property (nonatomic, strong) NSArray *colorArray;
@property (nonatomic, strong) NSString *filename; //Image filename

- (void) setSelectedBox:(int) i;
- (int) SelectedBox;
- (void) drawBox:(Box *)box context:(CGContextRef)context alpha:(CGFloat)alpha corners:(BOOL)hasCorners;
- (void) reset;
- (void)setLINEWIDTH:(float)factor;
- (int)whereIs:(CGPoint) point;
- (int)boxInterior:(int)i :(CGPoint)point;

@end
