//
//  Box.h
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Foundation/Foundation.h>

@interface Box : NSObject <NSCoding>{
    CGPoint upperLeft;
    CGPoint lowerRigth;
    NSString *      _label;
    UIColor *       _color;
    NSString * _date;
    float   UPPERBOUND;
    float   LOWERBOUND;
    float   LEFTBOUND;
    float   RIGHTBOUND;
    BOOL    sent;
    //float   LINEWIDTH;
}

@property (retain, nonatomic) NSString *label;
@property (retain, nonatomic) NSString *date;

@property (retain, nonatomic) UIColor *color;

- (id)initWithPoints:(CGPoint) upper:(CGPoint) lower;

-(void)setBounds:(CGRect)rect;
-(int) setUpperLeft:(CGPoint ) point;
-(int) setLowerRight:(CGPoint ) point;
-(CGPoint) upperLeft;
-(CGPoint) lowerRight;
-(void) updatePoints:(CGPoint) start:(CGPoint) end;
-(void) updateUpperLeft:(CGPoint) start:(CGPoint) end;
-(void) updateLowerRight:(CGPoint) start:(CGPoint) end;
-(CGPoint) bounds;
-(void)setSent:(BOOL)value;
-(BOOL)sent;
+(void)setLINEWIDTH:(float)value;
-(void)generateDateString;

@end
