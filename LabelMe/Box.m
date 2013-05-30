//
//  Box.m
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Box.h"
#import "Constants.h"

@implementation Box

@synthesize label = _label;
@synthesize color = _color;
@synthesize date = _date;
@synthesize downloadDate = _downloadDate;

static float LINEWIDTH = 6;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        upperLeft = CGPointMake(0, 0 );
        lowerRigth = CGPointMake(150, 150);
        self.label= @"";
        self.date= @"";

        self.color = [[UIColor alloc] init];
        sent = NO;
        
    }
    
    return self;
}
- (id)initWithPoints:(CGPoint)upper :(CGPoint) lower
{
    self = [super init];
    if (self) {
        upperLeft = upper;
        lowerRigth = lower;
        self.label= [NSString stringWithFormat:@""];
        sent = NO;
    }
    return self;
}
-(void)setBounds:(CGRect)rect{
   // UPPERBOUND = rect.origin.y;
    UPPERBOUND = 0;
    LOWERBOUND = rect.size.height;// - rect.origin.y;
    //LEFTBOUND = rect.origin.x;
    LEFTBOUND = 0;
    RIGHTBOUND = rect.size.width;// - rect.origin.x;
}
-(int) setUpperLeft:(CGPoint ) point{
    int corner=0;
    if (point.y<UPPERBOUND+LINEWIDTH/2) {
        point.y=UPPERBOUND +LINEWIDTH/2;
    }
    if (point.x<LEFTBOUND +LINEWIDTH/2) {
        point.x=LEFTBOUND +LINEWIDTH/2;
        
    }
    upperLeft = point;
   /* upperLeft.x /= RIGHTBOUND;
    upperLeft.y /= LOWERBOUND;*/
    if ((upperLeft.x>lowerRigth.x)) {
        float copy;
        copy=upperLeft.x;
        upperLeft.x=lowerRigth.x;
        lowerRigth.x=copy;
        corner++;
    }
    if ((upperLeft.y>lowerRigth.y)) {
        float copy;
        copy=upperLeft.y;
        upperLeft.y=lowerRigth.y;
        lowerRigth.y=copy;
        corner+=2;
    }
    
    
    return corner;
    
    
}
-(int) setLowerRight:(CGPoint ) point{
    int corner=0;
    if (point.y>LOWERBOUND-LINEWIDTH/2) {
        point.y=LOWERBOUND-LINEWIDTH/2;
    }
    if (point.x>RIGHTBOUND-LINEWIDTH/2) {
        point.x=RIGHTBOUND-LINEWIDTH/2;
    }
    lowerRigth = point;
   /* lowerRigth.x /= RIGHTBOUND;
    lowerRigth.y /= LOWERBOUND;*/
    if ((upperLeft.x>lowerRigth.x)) {
        float copy;
        copy=upperLeft.x;
        upperLeft.x=lowerRigth.x;
        lowerRigth.x=copy;
        corner++;
    }
    if ((upperLeft.y>lowerRigth.y)) {
        float copy;
        copy=upperLeft.y;
        upperLeft.y=lowerRigth.y;
        lowerRigth.y=copy;
        corner+=2;
    }
    
    
    return corner;
    
}

-(CGPoint) upperLeft{
    return upperLeft;
}
-(CGPoint) lowerRight{
    return lowerRigth;
}

-(void) updatePoints:(CGPoint)start :(CGPoint) end
{
    if (upperLeft.y+end.y-start.y<UPPERBOUND +LINEWIDTH/2) {
        end.y=UPPERBOUND+ LINEWIDTH/2-upperLeft.y+start.y;
        
    }
    if (lowerRigth.y+end.y-start.y>LOWERBOUND-LINEWIDTH/2) {
        end.y=LOWERBOUND-LINEWIDTH/2-lowerRigth.y+start.y;
        
        
    }
    if (upperLeft.x+end.x-start.x<LEFTBOUND +LINEWIDTH/2) {
        end.x=LEFTBOUND +LINEWIDTH/2-upperLeft.x+start.x;
        
    }
    if (lowerRigth.x+end.x-start.x>RIGHTBOUND-LINEWIDTH/2) {
        end.x=RIGHTBOUND-LINEWIDTH/2-lowerRigth.x+start.x;
        
    }
    
    upperLeft.x=(upperLeft.x+end.x-start.x);
    upperLeft.y=(upperLeft.y+end.y-start.y);
    lowerRigth.x=(lowerRigth.x+end.x-start.x);
    lowerRigth.y=(lowerRigth.y+end.y-start.y);
}


-(void) updateUpperLeft:(CGPoint)start :(CGPoint)end
{
    upperLeft.x=upperLeft.x+end.x-start.x;
    upperLeft.y=upperLeft.y+end.y-start.y;
    if (upperLeft.y<UPPERBOUND +LINEWIDTH/2) {
        upperLeft.y=UPPERBOUND +LINEWIDTH/2;
    }
    if (upperLeft.x<LEFTBOUND +LINEWIDTH/2) {
        upperLeft.x=LEFTBOUND +LINEWIDTH/2;
    }
    if ((upperLeft.x>lowerRigth.x)) {
        float copy;
        copy=upperLeft.x;
        upperLeft.x=lowerRigth.x;
        lowerRigth.x=copy;
    }
    if ((upperLeft.y>lowerRigth.y)) {
        float copy;
        copy=upperLeft.y;
        upperLeft.y=lowerRigth.y;
        lowerRigth.y=copy;
    }
}


-(void) updateLowerRight:(CGPoint)start :(CGPoint) end
{
    lowerRigth.x=lowerRigth.x+end.x-start.x;
    lowerRigth.y=lowerRigth.y+end.y-start.y;
    if (lowerRigth.y>LOWERBOUND-LINEWIDTH/2) {
        lowerRigth.y=LOWERBOUND-LINEWIDTH/2;
    }
    if (lowerRigth.x>RIGHTBOUND-LINEWIDTH/2) {
        lowerRigth.x=RIGHTBOUND-LINEWIDTH/2;
    }
    if ((upperLeft.x>lowerRigth.x)) {
        float copy;
        copy=upperLeft.x;
        upperLeft.x=lowerRigth.x;
        lowerRigth.x=copy;
    }
    if ((upperLeft.y>lowerRigth.y)) {
        float copy;
        copy=upperLeft.y;
        upperLeft.y=lowerRigth.y;
        lowerRigth.y=copy;
    }
}


-(void)generateDateString
{    
    NSString *originalDate = [[NSString alloc] initWithString:[[[NSDate date] description] substringToIndex:19]];
    //NSString *originalDate = [[NSString alloc] initWithString:@"0101010101010101010"];
    NSString *time = [[NSString alloc] initWithString:[originalDate substringFromIndex:11]];
    NSString *day = [[NSString alloc] initWithString:[originalDate substringWithRange:NSMakeRange(8, 2)]];
    NSString *year = [[NSString alloc] initWithString:[originalDate substringWithRange:NSMakeRange(0, 4)]];
    NSString *month = [[NSString alloc] initWithString:[originalDate substringWithRange:NSMakeRange(5, 2)]];
    int m = [month intValue];
    
    NSArray *months = [[NSArray alloc] initWithObjects:@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec",nil];
    NSString *month2 = [months objectAtIndex:m-1];
    NSString *tmp = [[NSString alloc] initWithFormat:@"%@-%@-%@-%@",day,month2,year,time ];
    self.date = tmp;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.label = [aDecoder decodeObjectForKey:@"label"];
        self.color = [aDecoder decodeObjectForKey:@"color"];
        self.date = [aDecoder decodeObjectForKey:@"date"];

        upperLeft.x = [aDecoder decodeFloatForKey:@"upperLeftx"];
        upperLeft.y = [aDecoder decodeFloatForKey:@"upperLefty"];
        lowerRigth.x = [aDecoder decodeFloatForKey:@"lowerRightx"];
        lowerRigth.y = [aDecoder decodeFloatForKey:@"lowerRighty"];
        UPPERBOUND = [aDecoder decodeFloatForKey:@"UPPERBOUND"];
        LOWERBOUND = [aDecoder decodeFloatForKey:@"LOWERBOUND"];
        RIGHTBOUND = [aDecoder decodeFloatForKey:@"RIGHTBOUND"];
        LEFTBOUND = [aDecoder decodeFloatForKey:@"LEFTBOUND"];
        LINEWIDTH = [aDecoder decodeFloatForKey:@"LINEWIDTH"];
        sent = [aDecoder decodeBoolForKey:@"sent"];



    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: self.label forKey:@"label"];
    [aCoder encodeObject:self.color forKey:@"color"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeFloat:upperLeft.x forKey:@"upperLeftx"];
    [aCoder encodeFloat:upperLeft.y forKey:@"upperLefty"];
    [aCoder encodeFloat:lowerRigth.x forKey:@"lowerRightx"];
    [aCoder encodeFloat:lowerRigth.y forKey:@"lowerRighty"];
    [aCoder encodeFloat:UPPERBOUND forKey:@"UPPERBOUND"];
    [aCoder encodeFloat:LOWERBOUND forKey:@"LOWERBOUND"];
    [aCoder encodeFloat:RIGHTBOUND forKey:@"RIGHTBOUND"];
    [aCoder encodeFloat:LEFTBOUND forKey:@"LEFTBOUND"];
    [aCoder encodeFloat:LINEWIDTH forKey:@"LINEWIDTH"];
    [aCoder encodeBool:sent forKey:@"sent"];
}


-(void)setSent:(BOOL)value
{
    sent = value;
}

-(BOOL)sent
{
    return sent;
}

-(CGPoint)bounds
{
    return CGPointMake(RIGHTBOUND, LOWERBOUND);
}

+(void)setLINEWIDTH:(float)value
{
    LINEWIDTH = value;
}

- (CGRect) getRectangleForBox
{
    CGRect rectangle = CGRectMake(upperLeft.x, upperLeft.y, lowerRigth.x - upperLeft.x, lowerRigth.y - upperLeft.y);
    return rectangle;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"upperLeft = (%.1f,%.1f), lowerRight = (%.1f,%.1f). Upper, lower, left and right bounds = (%.1f,%.1f,%.1f,%.1f)",upperLeft.x, upperLeft.y, lowerRigth.x,lowerRigth.y, UPPERBOUND, LOWERBOUND, LEFTBOUND, RIGHTBOUND];
}


@end