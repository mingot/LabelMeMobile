//
//  Box.m
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Updated by Josep Marc Mingot.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "Box.h"
#import "Constants.h"

//const NSArray *kColorArray = [[NSArray alloc] initWithObjects:[UIColor blueColor],[UIColor cyanColor],[UIColor greenColor],[UIColor magentaColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor purpleColor],[UIColor brownColor], nil];


#define DET 2 //Factor that represents the touchable area of the box corners
#define kLineWidth 6

#define kExteriorBox 0
#define kUpperLeft 1
#define kUpperRight 2
#define kLowerLeft 3
#define kLowerRight 4
#define kInteriorBox 5


@interface Box()
{
    int _cornerResizing;
    CGPoint _firstLocation;
}


- (NSString *) generateDateString;

- (void) resizeUpperLeftToPoint:(CGPoint)upperLeft;
- (void) resizeLowerRightToPoint:(CGPoint)lowerRight;

@end


@implementation Box


@synthesize upperLeft = _upperLeft;
@synthesize lowerRight = _lowerRight;

- (id) initWithUpperLeft:(CGPoint)upper lowerRight:(CGPoint)lower forImageSize:(CGSize)imageSize
{
    if (self = [super init]) {
        self.imageSize = imageSize;
        self.upperLeft = upper;
        self.lowerRight = lower;
        
        self.label= [NSString stringWithFormat:@""];
        self.date = [self generateDateString];
        self.color = [UIColor colorWithRed:(random()%100)/(float)100 green:(random()%100)/(float)100 blue:(random()%100)/(float)100 alpha:1];
        self.downloadDate = [NSDate date];
        self.sent = NO;
    }
    return self;
}

#pragma mark -
#pragma mark Touch Handling
- (int) touchAtPoint:(CGPoint)point
{

    int boxCorner = kExteriorBox;

    if ((CGRectContainsPoint(CGRectMake(self.upperLeft.x - DET*self.lineWidth,
                                        self.upperLeft.y - DET*self.lineWidth,
                                        2*DET*self.lineWidth,
                                        2*DET*self.lineWidth), point)))  {
        
        
        boxCorner = kUpperLeft;
        
    } else if ((CGRectContainsPoint(CGRectMake(self.lowerRight.x - DET*self.lineWidth,
                                               self.lowerRight.y - DET*self.lineWidth,
                                               2*DET*self.lineWidth,
                                               2*DET*self.lineWidth), point)))  {
        
        boxCorner = kLowerRight;
        
    } else if ((CGRectContainsPoint(CGRectMake(self.lowerRight.x - DET*self.lineWidth,
                                               self.upperLeft.y - DET*self.lineWidth,
                                               2*DET*self.lineWidth,
                                               2*DET*self.lineWidth), point)))  {
        
        boxCorner = kUpperRight;
        
    } else if ((CGRectContainsPoint(CGRectMake(self.upperLeft.x - DET*self.lineWidth,
                                               self.lowerRight.y - DET*self.lineWidth,
                                               2*DET*self.lineWidth,
                                               2*DET*self.lineWidth), point)))  {
        
        boxCorner = kLowerLeft;
        
    }else if ((CGRectContainsPoint(CGRectMake(self.upperLeft.x - self.lineWidth/2,
                                              self.upperLeft.y - self.lineWidth/2,
                                              self.lowerRight.x - self.upperLeft.x + self.lineWidth,
                                              self.lowerRight.y - self.upperLeft.y + self.lineWidth) , point))) {
        boxCorner = kInteriorBox;
    }
    
    return boxCorner;

}


#pragma mark -
#pragma mark Box resizing

- (void) resizeBeginAtPoint:(CGPoint)point
{
    int corner = [self touchAtPoint:point];
    _cornerResizing = corner;
}

- (void) resizeToPoint:(CGPoint)point
{
    switch (_cornerResizing) {
        case kUpperLeft:
            [self resizeUpperLeftToPoint:point];
            break;
            
        case kUpperRight:
            [self resizeUpperLeftToPoint:CGPointMake(self.upperLeft.x, point.y)];
            [self resizeLowerRightToPoint:CGPointMake(point.x, self.lowerRight.y)];
            break;
            
        case kLowerLeft:
            [self resizeUpperLeftToPoint:CGPointMake(point.x, self.upperLeft.y)];
            [self resizeLowerRightToPoint:CGPointMake(self.lowerRight.x, point.y)];
            break;
            
        case kLowerRight:
            [self resizeLowerRightToPoint:point];
            break;
            
        default:
            break;
    }
}


- (void) resizeLowerRightToPoint:(CGPoint)lowerRight
{
    self.lowerRight = lowerRight;
    int rotation = 0;
    if (_upperLeft.x > _lowerRight.x) {
        float copy;
        copy = _upperLeft.x;
        _upperLeft.x = _lowerRight.x;
        _lowerRight.x = copy;
        rotation++;
    }
    if (_upperLeft.y > _lowerRight.y) {
        float copy;
        copy = _upperLeft.y;
        _upperLeft.y = _lowerRight.y;
        _lowerRight.y = copy;
        rotation+=2;
    }
    
    _cornerResizing -= rotation;
}

- (void) resizeUpperLeftToPoint:(CGPoint)upperLeft
{
    self.upperLeft = upperLeft;
    int rotation = 0;
    if (_upperLeft.x > _lowerRight.x) {
        float copy;
        copy = _upperLeft.x;
        _upperLeft.x = _lowerRight.x;
        _lowerRight.x = copy;
        rotation++;
    }
    
    if (_upperLeft.y > _lowerRight.y) {
        float copy;
        copy = _upperLeft.y;
        _upperLeft.y = _lowerRight.y;
        _lowerRight.y = copy;
        rotation+=2;
    }
    _cornerResizing +=rotation;
}


#pragma mark - 
#pragma mark Box moving

- (void) moveBeginAtPoint:(CGPoint)point
{
    _firstLocation = point;
}

- (void) moveToPoint:(CGPoint)end
{
    
    if (self.upperLeft.y + end.y - _firstLocation.y < 0 + self.lineWidth/2) {
        end.y = 0 + self.lineWidth/2 - self.upperLeft.y + _firstLocation.y;
        
    }
    if (self.lowerRight.y + end.y - _firstLocation.y > self.imageSize.height - self.lineWidth/2) {
        end.y = self.imageSize.height - self.lineWidth/2 - self.lowerRight.y + _firstLocation.y;
        
        
    }
    if (self.upperLeft.x + end.x - _firstLocation.x < 0 + self.lineWidth/2) {
        end.x = 0 + self.lineWidth/2 - self.upperLeft.x + _firstLocation.x;
        
    }
    if (self.lowerRight.x + end.x - _firstLocation.x > self.imageSize.width - self.lineWidth/2) {
        end.x = self.imageSize.width - self.lineWidth/2 - self.lowerRight.x + _firstLocation.x;
        
    }
    
    self.upperLeft = CGPointMake((self.upperLeft.x + end.x - _firstLocation.x), (self.upperLeft.y + end.y - _firstLocation.y));
    self.lowerRight = CGPointMake((self.lowerRight.x + end.x - _firstLocation.x), (self.lowerRight.y + end.y - _firstLocation.y));
    
    _firstLocation = end;
}

#pragma mark -
#pragma mark Private Methods

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
        
        _upperLeft.x = [aDecoder decodeFloatForKey:@"upperLeftx"];
        _upperLeft.y = [aDecoder decodeFloatForKey:@"upperLefty"];
        _lowerRight.x = [aDecoder decodeFloatForKey:@"lowerRightx"];
        _lowerRight.y = [aDecoder decodeFloatForKey:@"lowerRighty"];
        self.sent = [aDecoder decodeBoolForKey:@"sent"];
        
        //compatibility with LabelMe 1.0
        CGSize imageSize;
        if ([aDecoder containsValueForKey:@"imageSize"]) { //new model
            imageSize = [aDecoder decodeCGSizeForKey:@"imageSize"];
            
        } else { //old model
            CGFloat UPPERBOUND = [aDecoder decodeFloatForKey:@"UPPERBOUND"];
            CGFloat LOWERBOUND = [aDecoder decodeFloatForKey:@"LOWERBOUND"];
            CGFloat RIGHTBOUND = [aDecoder decodeFloatForKey:@"RIGHTBOUND"];
            CGFloat LEFTBOUND = [aDecoder decodeFloatForKey:@"LEFTBOUND"];
            
            imageSize.height = LOWERBOUND - UPPERBOUND;
            imageSize.width = RIGHTBOUND - LEFTBOUND;
        }
        
        self.imageSize = imageSize;

    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeFloat:self.upperLeft.x forKey:@"upperLeftx"];
    [aCoder encodeFloat:self.upperLeft.y forKey:@"upperLefty"];
    [aCoder encodeFloat:self.lowerRight.x forKey:@"lowerRightx"];
    [aCoder encodeFloat:self.lowerRight.y forKey:@"lowerRighty"];
    [aCoder encodeObject:self.label forKey:@"label"];
    [aCoder encodeObject:self.color forKey:@"color"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeCGSize:self.imageSize forKey:@"imageSize"];
    [aCoder encodeBool:self.sent forKey:@"sent"];
}



- (CGRect) getRectangleForBox
{
    CGRect rectangle = CGRectMake(self.upperLeft.x, self.upperLeft.y, self.lowerRight.x - self.upperLeft.x, self.lowerRight.y - self.upperLeft.y);
    return rectangle;
}

- (void) setBoxDimensionsForFrameSize:(CGSize) size
{    
    self.upperLeft = CGPointMake(self.upperLeft.x*size.width*1.0/self.imageSize.width, self.upperLeft.y*size.height*1.0/self.imageSize.height);
    self.lowerRight = CGPointMake(self.lowerRight.x*size.width*1.0/self.imageSize.width, self.lowerRight.y*size.height*1.0/self.imageSize.height);
    self.imageSize = size;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"upperLeft = (%.1f,%.1f), lowerRight = (%.1f,%.1f). Upper, lower, left and right bounds = (%.1f,%.1f,%.1f,%.1f)",self.upperLeft.x, self.upperLeft.y, self.lowerRight.x,self.lowerRight.y, 0.0, self.imageSize.height, 0.0, self.imageSize.width];
}


@end
