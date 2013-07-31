//
//  TagView.m
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "TagView.h"
#import "Constants.h"
#import "UITextField+CorrectOrientation.h"

#define NO_BOX_SELECTED -1
#define DET 2


@implementation TagView


#pragma mark -
#pragma mark Initialization

- (void) initialize
{
    [self setBackgroundColor:[UIColor clearColor]];
    self.boxes = [[NSMutableArray alloc] init];
    
    move = NO;
    size = NO;
    corner = -1;
    self.colorArray=[[NSArray alloc] initWithObjects:[UIColor blueColor],[UIColor cyanColor],[UIColor greenColor],[UIColor magentaColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor purpleColor],[UIColor brownColor], nil];
    selectedBox = NO_BOX_SELECTED;
    lineOriginal = 6;
    LINEWIDTH = 6;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) [self initialize];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self= [super initWithFrame:frame]) [self initialize];
    return self;
}


#pragma mark -
#pragma mark Draw Rect

- (void) drawRect:(CGRect)rect
{
    if (self.boxes.count<1)
        return;
   
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, LINEWIDTH);
    
    for(int i=0; i<self.boxes.count; i++){
        
        Box *box = [self.boxes objectAtIndex:i];
        if(selectedBox == NO_BOX_SELECTED)
            [self drawBox:box context:context alpha:1 corners:false];
        else if(selectedBox == i)
            [self drawBox:box context:context alpha:1 corners:true];
        else
            [self drawBox:box context:context alpha:0.3 corners:false];
                
    }
}


-(void) drawBox:(Box *)box context:(CGContextRef)context alpha:(CGFloat)alpha corners:(BOOL)hasCorners
{
    
    CGPoint upperRight = CGPointMake([box lowerRight].x, [box upperLeft].y);
    CGPoint lowerLeft = CGPointMake([box upperLeft].x, [box lowerRight].y);
    
    // DRAW RECT
    CGContextSetLineWidth(context, LINEWIDTH);
    CGRect rect = CGRectMake([box upperLeft].x, [box upperLeft].y, [box lowerRight].x-[box upperLeft].x, [box lowerRight].y-[box upperLeft].y);
    const CGFloat *components = CGColorGetComponents(box.color.CGColor);
    CGContextSetRGBStrokeColor(context, components[0] ,components[1],components[2], alpha);
    CGContextStrokeRect(context, rect);
    
    // DRAW CORNERS
    if(hasCorners){
        CGContextStrokeEllipseInRect(context, CGRectMake([box upperLeft].x-LINEWIDTH, [box upperLeft].y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake([box lowerRight].x-LINEWIDTH, [box lowerRight].y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-LINEWIDTH, upperRight.y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-LINEWIDTH, lowerLeft.y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
        CGContextSetRGBStrokeColor(context, 255, 255, 255, 1);
        CGContextSetLineWidth(context, 1);
        CGContextStrokeEllipseInRect(context, CGRectMake([box upperLeft].x-1.5*LINEWIDTH, [box upperLeft].y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake([box lowerRight].x-1.5*LINEWIDTH, [box lowerRight].y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-1.5*LINEWIDTH, upperRight.y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
        CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-1.5*LINEWIDTH, lowerLeft.y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
    }
}




#pragma mark -
#pragma mark Touch Events

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    
    //a box is selected
    if (selectedBox != NO_BOX_SELECTED) {
        Box *currentBox = [self.boxes objectAtIndex:selectedBox];
        [currentBox setBounds:self.frame];

        
        if ((CGRectContainsPoint(CGRectMake([currentBox upperLeft].x-DET*LINEWIDTH,
                                            [currentBox upperLeft].y-DET*LINEWIDTH,
                                            2*DET*LINEWIDTH,
                                            2*DET*LINEWIDTH), location)))  {
        
            size = YES;
            corner = 1;
            
        } else if ((CGRectContainsPoint(CGRectMake([currentBox lowerRight].x-DET*LINEWIDTH,
                                                   [currentBox lowerRight].y-DET*LINEWIDTH,
                                                   2*DET*LINEWIDTH,
                                                   2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 4;
            
        } else if ((CGRectContainsPoint(CGRectMake([currentBox lowerRight].x-DET*LINEWIDTH,
                                                   [currentBox upperLeft].y-DET*LINEWIDTH,
                                                   2*DET*LINEWIDTH,
                                                   2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 2;
            
        } else if ((CGRectContainsPoint(CGRectMake([currentBox upperLeft].x-DET*LINEWIDTH,
                                                   [currentBox lowerRight].y-DET*LINEWIDTH,
                                                   2*DET*LINEWIDTH,
                                                   2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 3;
            
        }else if ((CGRectContainsPoint(CGRectMake([currentBox upperLeft].x-LINEWIDTH/2,
                                                  [currentBox upperLeft].y-LINEWIDTH/2,
                                                  [currentBox lowerRight].x-[currentBox upperLeft].x+LINEWIDTH,
                                                  [currentBox lowerRight].y-[currentBox upperLeft].y+LINEWIDTH) , location))) {
          
            move = YES;
            firstLocation = location;
            
        }else{
            [self.delegate selectedAnObject:NO];
            selectedBox = NO_BOX_SELECTED;
            [self.delegate hiddenTextField:YES];
        }
        
    //no box selected
    }else{
        
        //locate if there is any box at the point touched
        selectedBox = [self whereIs:location];
        
        if (selectedBox != NO_BOX_SELECTED) {
            [self.delegate hiddenTextField:NO];
            Box *currentBox=[self.boxes objectAtIndex: selectedBox];
            [self.delegate selectedAnObject:YES];
            [currentBox setBounds:self.frame];

            [self.delegate stringLabel:currentBox.label];
            [self.delegate correctOrientationForBox:currentBox SuperviewFrame:self.frame];
            move = NO;
            size = NO;
            
        }else{
            size = NO;
            move = NO;
            [self.delegate selectedAnObject:NO];            
        }
    }
}



-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    [self.delegate hiddenTextField:YES];
    
    Box *currentBox;
    if (move) {
        currentBox = [self.boxes objectAtIndex:selectedBox];
        [currentBox updatePoints:firstLocation :location];        
    }
    
    else if (size){
        currentBox = [self.boxes objectAtIndex:selectedBox];

        switch (corner) {
            case 1:
                corner += [currentBox setUpperLeft:location];
                break;
            case 2:
                corner += [currentBox setUpperLeft:CGPointMake([currentBox upperLeft].x, location.y)]-[currentBox setLowerRight:CGPointMake(location.x, [currentBox lowerRight].y)];
                break;
            case 3:
                corner += [currentBox setUpperLeft:CGPointMake(location.x, [currentBox upperLeft].y)]-[currentBox setLowerRight:CGPointMake([currentBox lowerRight].x, location.y)];
                break;
            case 4:
                corner-=[currentBox setLowerRight:location];
                break;
                
            default:
                break;
        }
    }
     firstLocation=location;
    [self setNeedsDisplay];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

    if ((move) || (size))
        [self.delegate objectModified];
    
    if (selectedBox != NO_BOX_SELECTED) {
        Box *currentBox =  [self.boxes objectAtIndex: selectedBox];
        [self.delegate correctOrientationForBox:currentBox SuperviewFrame:self.frame];
        [self.delegate hiddenTextField:NO];
    }
    
    move = NO;
    size = NO;
    corner = -1;

    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Search Box

-(int)whereIs:(CGPoint) point
{
    
    for (int j=0; j<self.boxes.count; j++) {
        Box *newBox = [self.boxes objectAtIndex:j];
        if (CGRectContainsPoint(CGRectMake([newBox upperLeft].x-LINEWIDTH,
                                           [newBox upperLeft].y-LINEWIDTH,
                                           [newBox lowerRight].x-[newBox upperLeft].x+2*LINEWIDTH,
                                           [newBox lowerRight].y-[newBox upperLeft].y+2*LINEWIDTH),point)) {
            return [self boxInterior:j :point];
        }
    }
    return -1;
}

-(int)boxInterior:(int)i :(CGPoint)point
{

    int num = [self.boxes count];
    for (int j=i+1; j<num; j++) {
        Box *newBox = [self.boxes objectAtIndex: j];
        NSLog(@"%@", [newBox description]);
       // [newBox setBounds:self.frame];

        if (CGRectContainsPoint( CGRectMake([newBox upperLeft].x-LINEWIDTH, [newBox upperLeft].y-LINEWIDTH, [newBox lowerRight].x-[newBox upperLeft].x+2*LINEWIDTH, [newBox lowerRight].y-[newBox upperLeft].y+2*LINEWIDTH),point)) {
            Box *currentBox = [self.boxes objectAtIndex: i];
           // [currentBox setBounds:self.frame];

            if (CGRectContainsRect( CGRectMake([newBox upperLeft].x-LINEWIDTH, [newBox upperLeft].y-LINEWIDTH, [newBox lowerRight].x-[newBox upperLeft].x+2*LINEWIDTH, [newBox lowerRight].y-[newBox upperLeft].y+2*LINEWIDTH),CGRectMake([currentBox upperLeft].x-LINEWIDTH, [currentBox upperLeft].y-LINEWIDTH, [currentBox lowerRight].x-[currentBox upperLeft].x+2*LINEWIDTH, [currentBox lowerRight].y-[currentBox upperLeft].y+2*LINEWIDTH))){
                
                if ([self boxInterior:j :point]==j)
                    return i;
                
            }
            return [self boxInterior:j:point];
        }
    }    
    return i;  
}


#pragma mark -
#pragma mark Selected Box

-(void) setSelectedBox:(int) i
{
    selectedBox = i;
    if(i != NO_BOX_SELECTED){
        Box *currentBox = [self.boxes objectAtIndex:selectedBox];
        [self.delegate hiddenTextField:NO];
        [self.delegate stringLabel:currentBox.label];
    
    }else [self.delegate hiddenTextField:YES];
    
}

-(int) SelectedBox
{
    return selectedBox;
}

#pragma mark -
#pragma mark Reset

-(void) reset
{
    [self.delegate hiddenTextField:YES];
    selectedBox = NO_BOX_SELECTED;
    [self.boxes removeAllObjects];
    move = NO;
    size = NO;
}


#pragma mark -
#pragma mark Date String

-(NSString *)generateDateString
{
    NSString *originalDate = [[[NSDate date] description] substringToIndex:19];
    NSString *time = [originalDate substringFromIndex:11];
    NSString *day = [originalDate substringWithRange:NSMakeRange(8, 2)];
    NSString *year = [originalDate substringWithRange:NSMakeRange(0, 4)];
    NSString *month = [originalDate substringWithRange:NSMakeRange(5, 2)];
    NSArray *months = [NSArray arrayWithObjects:@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug",@"Sep",@"Oct",@"Nov",@"Dec", nil];
    month = [months objectAtIndex:month.intValue - 1];
    
    return [NSString stringWithFormat:@"%@-%@-%@ -%@",day,month,year,time];
}


#pragma mark -
#pragma mark Other

-(void)setLINEWIDTH:(float)factor
{
    LINEWIDTH = lineOriginal / factor;
    [self setNeedsDisplay];
}



@end
