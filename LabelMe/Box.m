//
//  Box.m
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Box.h"
#import "Constants.h"

@interface Box()
{
}

@end


@implementation Box

@synthesize label = _label;
@synthesize color = _color;
@synthesize date = _date;
@synthesize downloadDate = _downloadDate;


- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        upperLeft = CGPointMake(0, 0 );
        lowerRigth = CGPointMake(150, 150);
        self.label= @"";
        self.date= [self generateDateString];
        self.color = [[UIColor alloc] init];
        self.downloadDate = [NSDate date];
        self.sent = NO;
        
    }
    
    return self;
}

- (id)initWithPoints:(CGPoint)upper :(CGPoint)lower
{
    self = [super init];
    if (self) {
        upperLeft = upper;
        lowerRigth = lower;
        self.date = [self generateDateString];
        self.label= [NSString stringWithFormat:@""];
        self.downloadDate = [NSDate date];
        self.sent = NO;
    }
    return self;
}


-(void)setBounds:(CGRect)rect
{
    self.imageSize = rect.size;
}


-(int) setUpperLeft:(CGPoint ) point
{
    int corner=0;
    if (point.y < 0 + self.lineWidth/2) point.y = 0 + self.lineWidth/2;
    
    if (point.x < 0 + self.lineWidth/2) point.x = 0 + self.lineWidth/2;
    
    upperLeft = point;

    if (upperLeft.x > lowerRigth.x) {
        float copy;
        copy = upperLeft.x;
        upperLeft.x = lowerRigth.x;
        lowerRigth.x = copy;
        corner++;
    }
    
    if (upperLeft.y > lowerRigth.y) {
        float copy;
        copy = upperLeft.y;
        upperLeft.y = lowerRigth.y;
        lowerRigth.y = copy;
        corner+=2;
    }
    
    return corner;
}

-(int) setLowerRight:(CGPoint ) point
{
    int corner=0;
    if (point.y > self.imageSize.height - self.lineWidth/2) {
        point.y = self.imageSize.height - self.lineWidth/2;
    }
    if (point.x > self.imageSize.width - self.lineWidth/2) {
        point.x = self.imageSize.width - self.lineWidth/2;
    }
    lowerRigth = point;

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

-(CGPoint) upperLeft
{
    return upperLeft;
}

-(CGPoint) lowerRight
{
    return lowerRigth;
}

-(void) updatePoints:(CGPoint)start :(CGPoint) end
{
    if (upperLeft.y + end.y - start.y<0 + self.lineWidth/2) {
        end.y = 0 + self.lineWidth/2 - upperLeft.y + start.y;
        
    }
    if (lowerRigth.y + end.y - start.y > self.imageSize.height - self.lineWidth/2) {
        end.y = self.imageSize.height - self.lineWidth/2 - lowerRigth.y + start.y;
        
        
    }
    if (upperLeft.x + end.x - start.x < 0 + self.lineWidth/2) {
        end.x = 0 + self.lineWidth/2 - upperLeft.x + start.x;
        
    }
    if (lowerRigth.x + end.x - start.x > self.imageSize.width - self.lineWidth/2) {
        end.x = self.imageSize.width - self.lineWidth/2 - lowerRigth.x + start.x;
        
    }
    
    upperLeft.x = (upperLeft.x+end.x - start.x);
    upperLeft.y = (upperLeft.y+end.y - start.y);
    lowerRigth.x = (lowerRigth.x+end.x - start.x);
    lowerRigth.y = (lowerRigth.y+end.y - start.y);
}





- (NSString *)generateDateString
{
    const NSArray *MONTHS = [[NSArray alloc] initWithObjects:@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec",nil];
    
    NSString *originalDate = [[NSString alloc] initWithString:[[[NSDate date] description] substringToIndex:19]];
    NSString *time = [[NSString alloc] initWithString:[originalDate substringFromIndex:11]];
    NSString *day = [[NSString alloc] initWithString:[originalDate substringWithRange:NSMakeRange(8, 2)]];
    NSString *year = [[NSString alloc] initWithString:[originalDate substringWithRange:NSMakeRange(0, 4)]];
    NSString *month = [[NSString alloc] initWithString:[originalDate substringWithRange:NSMakeRange(5, 2)]];
    month = [MONTHS objectAtIndex:[month intValue]-1];
    
    return [[NSString alloc] initWithFormat:@"%@-%@-%@-%@",day,month,year,time ]; 
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
        self.imageSize = [aDecoder decodeCGSizeForKey:@"imageSize"];
        self.lineWidth = [aDecoder decodeFloatForKey:@"lineWidth"];
        self.sent = [aDecoder decodeBoolForKey:@"sent"];

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
    [aCoder encodeCGSize:self.imageSize forKey:@"imageSize"];
    [aCoder encodeFloat:self.lineWidth forKey:@"lineWidth"];
    [aCoder encodeBool:self.sent forKey:@"sent"];
}




-(CGPoint)bounds
{
    return CGPointMake(self.imageSize.width, self.imageSize.height);
}

- (CGRect) getRectangleForBox
{
    CGRect rectangle = CGRectMake(upperLeft.x, upperLeft.y, lowerRigth.x - upperLeft.x, lowerRigth.y - upperLeft.y);
    return rectangle;
}

- (void) setBoxDimensionsForImageSize:(CGSize) size
{    
    upperLeft = CGPointMake(upperLeft.x*size.width*1.0/self.imageSize.width, upperLeft.y*size.height*1.0/self.imageSize.height);
    lowerRigth = CGPointMake(lowerRigth.x*size.width*1.0/self.imageSize.width, lowerRigth.y*size.height*1.0/self.imageSize.height);
    self.imageSize = size;
}

- (void) setLimitsForImageSize:(CGSize)size
{
    self.imageSize = size;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"upperLeft = (%.1f,%.1f), lowerRight = (%.1f,%.1f). Upper, lower, left and right bounds = (%.1f,%.1f,%.1f,%.1f)",upperLeft.x, upperLeft.y, lowerRigth.x,lowerRigth.y, 0.0, self.imageSize.height, 0.0, self.imageSize.width];
}


@end
