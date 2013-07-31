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

#import "NSString+checkValidity.h" //replacebyunderscore
#import "UITextField+CorrectOrientation.h" //correct label position when selecting a box.

#define NO_BOX_SELECTED -1
#define kLineWidth 6


#define kExteriorBox 0
#define kUpperLeft 1
#define kUpperRight 2
#define kLowerLeft 3
#define kLowerRight 4
#define kInteriorBox 5



@interface TagView()
{
    float _lineWidth;
    int selectedBox;
    BOOL move;
    BOOL size;
}

- (int) whereIs:(CGPoint) point;
- (int) boxInterior:(int)i :(CGPoint)point;
- (void) drawBox:(Box *)box context:(CGContextRef)context alpha:(CGFloat)alpha corners:(BOOL)hasCorners;

@end


@implementation TagView


#pragma mark -
#pragma mark Initialization

- (void) initialize
{
    [self setBackgroundColor:[UIColor clearColor]];
    self.boxes = [[NSMutableArray alloc] init];
    
    move = NO;
    size = NO;

    selectedBox = NO_BOX_SELECTED;
    _lineWidth = kLineWidth;
    
    //label initialization
    self.label = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 130, 40)];
    [self.label setBorderStyle:UITextBorderStyleNone];
    [self.label setKeyboardAppearance:UIKeyboardAppearanceAlert];
    [self.label addTarget:self
                   action:@selector(labelFinish:)
         forControlEvents:UIControlEventEditingDidEndOnExit];
    [self addSubview:self.label];
    self.label.placeholder = @"Enter Label:";
    self.label.textAlignment = UITextAlignmentCenter;
    self.label.adjustsFontSizeToFitWidth = YES;
    self.label.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.label.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder]) [self initialize];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) [self initialize];
    return self;
}


#pragma mark -
#pragma mark Getters and Setters

-(void) setSelectedBox:(int) i
{
    selectedBox = i;
    if(i != NO_BOX_SELECTED){
        Box *currentBox = [self.boxes objectAtIndex:selectedBox];
        [self.label fitForBox:currentBox onTagViewFrame:self.frame andScale:1.0];
        self.label.hidden = NO;
        self.label.text = currentBox.label;
        
    }else self.label.hidden = YES; 
}

-(int) selectedBox
{
    return selectedBox;
}

#pragma mark -
#pragma mark Public Methods

- (void) setLineWidthForZoomFactor:(float)factor;
{
    _lineWidth = kLineWidth / factor;
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Draw Rect

- (void) drawRect:(CGRect)rect
{
    if (self.boxes.count<1)
        return;
   
    CGContextRef context = UIGraphicsGetCurrentContext();
    
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
    CGContextSetLineWidth(context, _lineWidth);
    CGRect rect = CGRectMake([box upperLeft].x, [box upperLeft].y, [box lowerRight].x-[box upperLeft].x, [box lowerRight].y-[box upperLeft].y);
    const CGFloat *components = CGColorGetComponents(box.color.CGColor);
    CGContextSetRGBStrokeColor(context, components[0] ,components[1],components[2], alpha);
    CGContextStrokeRect(context, rect);
    
    // DRAW CORNERS
    if(hasCorners){
        CGContextStrokeEllipseInRect(context, CGRectMake([box upperLeft].x-_lineWidth, [box upperLeft].y-_lineWidth, 2*_lineWidth, 2*_lineWidth));
        CGContextStrokeEllipseInRect(context, CGRectMake([box lowerRight].x-_lineWidth, [box lowerRight].y-_lineWidth, 2*_lineWidth, 2*_lineWidth));
        CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-_lineWidth, upperRight.y-_lineWidth, 2*_lineWidth, 2*_lineWidth));
        CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-_lineWidth, lowerLeft.y-_lineWidth, 2*_lineWidth, 2*_lineWidth));
        CGContextSetRGBStrokeColor(context, 255, 255, 255, 1);
        CGContextSetLineWidth(context, 1);
        CGContextStrokeEllipseInRect(context, CGRectMake([box upperLeft].x-1.5*_lineWidth, [box upperLeft].y-1.5*_lineWidth, 3*_lineWidth, 3*_lineWidth));
        CGContextStrokeEllipseInRect(context, CGRectMake([box lowerRight].x-1.5*_lineWidth, [box lowerRight].y-1.5*_lineWidth, 3*_lineWidth, 3*_lineWidth));
        CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-1.5*_lineWidth, upperRight.y-1.5*_lineWidth, 3*_lineWidth, 3*_lineWidth));
        CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-1.5*_lineWidth, lowerLeft.y-1.5*_lineWidth, 3*_lineWidth, 3*_lineWidth));
    }
}




#pragma mark -
#pragma mark Touch Event Delegate

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    
    //a box is selected
    if (selectedBox != NO_BOX_SELECTED) {
        Box *currentBox = [self.boxes objectAtIndex:selectedBox];

        int corner = [currentBox touchAtPoint:location];
        
        if(corner == kInteriorBox){
            move = YES;
            [currentBox moveBeginAtPoint:location];
            
        }else if(corner == kExteriorBox){
            [self.delegate selectedAnObject:NO];
            selectedBox = NO_BOX_SELECTED;
            self.label.hidden = YES;
            
        }else{
            size = YES;
            [currentBox resizeBeginAtPoint:location];
        }
        
    }else{
        
        //locate if there is any box at the point touched
        selectedBox = [self whereIs:location];
        
        if (selectedBox != NO_BOX_SELECTED) {
            self.label.hidden = NO;
            [self.delegate selectedAnObject:YES];
            
            
            Box *currentBox = [self.boxes objectAtIndex:selectedBox];
            currentBox.imageSize = self.frame.size;
            
            self.label.text = currentBox.label;
            [self.label fitForBox:currentBox onTagViewFrame:self.frame andScale:1];
            
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
    self.label.hidden = YES;
    
    if(selectedBox != NO_BOX_SELECTED){
        Box *currentBox = [self.boxes objectAtIndex:selectedBox];
        if (move) [currentBox moveToPoint:location];
        else if (size) [currentBox resizeToPoint:location];
    }
    
    [self setNeedsDisplay];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

    if ((move) || (size)) [self.delegate objectModified];
    
    if (selectedBox != NO_BOX_SELECTED) {
        Box *currentBox =  [self.boxes objectAtIndex: selectedBox];
        
        [self.label fitForBox:currentBox onTagViewFrame:self.frame andScale:1];
        self.label.hidden = NO;
        
    }
    
    move = NO;
    size = NO;

    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Label Handling

- (IBAction)labelFinish:(id)sender
{
    int selected = self.selectedBox;
    self.label.text = [self.label.text replaceByUnderscore];
    Box *box = [self.boxes objectAtIndex:selected];
    if (![box.label isEqualToString:self.label.text]) { //update the name
        
        box.label = self.label.text;
        [box.label replaceByUnderscore];
        
        //put the boxes corresponding to the same object with the same color
        if (![self.label.text isEqualToString:@""]) {
            for (int i=0; i<self.boxes.count; i++) {
                if (i==selected)
                    continue;
                Box *oldBox = [self.boxes objectAtIndex:i];
                if ([box.label isEqualToString:oldBox.label]) {
                    box.color = oldBox.color;
                    break;
                }
            }
        }
        [self.delegate objectModified];
    }
    
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Private methods

-(int)whereIs:(CGPoint) point
{
    
    for (int j=0; j<self.boxes.count; j++) {
        Box *newBox = [self.boxes objectAtIndex:j];
        if (CGRectContainsPoint(CGRectMake([newBox upperLeft].x - _lineWidth,
                                           [newBox upperLeft].y - _lineWidth,
                                           [newBox lowerRight].x - [newBox upperLeft].x+2*_lineWidth,
                                           [newBox lowerRight].y - [newBox upperLeft].y+2*_lineWidth),point)) {
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

        if (CGRectContainsPoint( CGRectMake([newBox upperLeft].x-_lineWidth, [newBox upperLeft].y-_lineWidth, [newBox lowerRight].x-[newBox upperLeft].x+2*_lineWidth, [newBox lowerRight].y-[newBox upperLeft].y+2*_lineWidth),point)) {
            Box *currentBox = [self.boxes objectAtIndex: i];
           // [currentBox setBounds:self.frame];

            if (CGRectContainsRect( CGRectMake([newBox upperLeft].x-_lineWidth, [newBox upperLeft].y-_lineWidth, [newBox lowerRight].x-[newBox upperLeft].x+2*_lineWidth, [newBox lowerRight].y-[newBox upperLeft].y+2*_lineWidth),CGRectMake([currentBox upperLeft].x-_lineWidth, [currentBox upperLeft].y-_lineWidth, [currentBox lowerRight].x-[currentBox upperLeft].x+2*_lineWidth, [currentBox lowerRight].y-[currentBox upperLeft].y+2*_lineWidth))){
                
                if ([self boxInterior:j :point]==j)
                    return i;
                
            }
            return [self boxInterior:j:point];
        }
    }    
    return i;  
}

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



@end
