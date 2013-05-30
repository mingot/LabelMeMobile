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

@implementation TagView


- (id)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor ]];
        self.objects = [[NSMutableArray alloc]init] ;
        
        move = NO;
        size = NO;
        corner = -1;
        self.colorArray=[[NSArray alloc] initWithObjects:[UIColor blueColor],[UIColor cyanColor],[UIColor greenColor],[UIColor magentaColor],[UIColor orangeColor],[UIColor yellowColor],[UIColor purpleColor],[UIColor brownColor], nil];
        selectedBox = -1;
        lineOriginal = 6;
        LINEWIDTH = 6;

    }
    return self;
}


#pragma mark -
#pragma mark Draw Rect
- (void)drawRect:(CGRect)rect
{
    int count = self.objects.count;
    if (count<1) {
        return;
    }
   
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, LINEWIDTH);
    if (selectedBox==-1) {
        for (int i= 0; i<count; i++) {
            [self drawBox:context:[self.objects objectAtIndex:i]:1];
        }

    }
    else{
        for (int i=0; i<count; i++) {
            if (i == selectedBox) continue;
            [self drawBox:context:[self.objects objectAtIndex:i]:0.3];
        }
        [self drawSelectedBox:context:[self.objects objectAtIndex:selectedBox]];
    }
}

-(void) drawSelectedBox:(CGContextRef )context :(Box *) box1
{
    
    CGPoint upperRight = CGPointMake([box1 lowerRight].x, [box1 upperLeft].y);
    CGPoint lowerLeft = CGPointMake([box1 upperLeft].x, [box1 lowerRight].y);
    // DRAW RECT
    CGRect rect = CGRectMake([box1 upperLeft].x, [box1 upperLeft].y, [box1 lowerRight].x-[box1 upperLeft].x, [box1 lowerRight].y-[box1 upperLeft].y);
    //CGContextSetRGBStrokeColor(context, 255, 0, 0, 1);
    CGContextSetStrokeColorWithColor(context, box1.color.CGColor);
    CGContextStrokeRect(context, rect );
    // DRAW CORNERS
    CGContextStrokeEllipseInRect(context, CGRectMake([box1 upperLeft].x-LINEWIDTH, [box1 upperLeft].y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
    CGContextStrokeEllipseInRect(context, CGRectMake([box1 lowerRight].x-LINEWIDTH, [box1 lowerRight].y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
    CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-LINEWIDTH, upperRight.y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
    CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-LINEWIDTH, lowerLeft.y-LINEWIDTH, 2*LINEWIDTH, 2*LINEWIDTH));
    CGContextSetRGBStrokeColor(context, 255, 255, 255, 1);
    CGContextSetLineWidth(context, 1);
    CGContextStrokeEllipseInRect(context, CGRectMake([box1 upperLeft].x-1.5*LINEWIDTH, [box1 upperLeft].y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
    CGContextStrokeEllipseInRect(context, CGRectMake([box1 lowerRight].x-1.5*LINEWIDTH, [box1 lowerRight].y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
    CGContextStrokeEllipseInRect(context, CGRectMake(upperRight.x-1.5*LINEWIDTH, upperRight.y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
    CGContextStrokeEllipseInRect(context, CGRectMake(lowerLeft.x-1.5*LINEWIDTH, lowerLeft.y-1.5*LINEWIDTH, 3*LINEWIDTH, 3*LINEWIDTH));
    
}

-(void) drawBox:(CGContextRef )context :(Box *)box1 :(CGFloat) alpha
{
    const CGFloat *components = CGColorGetComponents(box1.color.CGColor);
    CGContextBeginPath(context);
    CGContextSetRGBStrokeColor(context, components[0] ,components[1],components[2], alpha);
    CGContextAddRect(context, CGRectMake([box1 upperLeft].x, [box1 upperLeft].y, [box1 lowerRight].x-[box1 upperLeft].x, [box1 lowerRight].y-[box1 upperLeft].y) );
    CGContextClosePath(context);
    CGContextStrokePath(context);
}


#pragma mark -
#pragma mark Touch Events

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    
    //a box is selected
    if (selectedBox != -1) {
        Box *currentBox = [self.objects objectAtIndex: selectedBox];
        [currentBox setBounds:self.frame];

        if ((CGRectContainsPoint(CGRectMake([currentBox upperLeft].x-DET*LINEWIDTH, [currentBox upperLeft].y-DET*LINEWIDTH,2*DET*LINEWIDTH,2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 1;
            
        } else if ((CGRectContainsPoint(CGRectMake([currentBox lowerRight].x-DET*LINEWIDTH, [currentBox lowerRight].y-DET*LINEWIDTH,2*DET*LINEWIDTH,2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 4;
            
        } else if ((CGRectContainsPoint(CGRectMake([currentBox lowerRight].x-DET*LINEWIDTH, [currentBox upperLeft].y-DET*LINEWIDTH,2*DET*LINEWIDTH,2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 2;
            
        } else if ((CGRectContainsPoint(CGRectMake([currentBox upperLeft].x-DET*LINEWIDTH, [currentBox lowerRight].y-DET*LINEWIDTH,2*DET*LINEWIDTH,2*DET*LINEWIDTH), location)))  {
            size = YES;
            corner = 3;
            
        }else if ((CGRectContainsPoint(CGRectMake([currentBox upperLeft].x-LINEWIDTH/2, [currentBox upperLeft].y-LINEWIDTH/2, [currentBox lowerRight].x-[currentBox upperLeft].x+LINEWIDTH, [currentBox lowerRight].y-[currentBox upperLeft].y+LINEWIDTH) , location))) {
          
            move = YES;
            firstLocation = location;
        }else{
            [self.delegate selectedAnObject:NO];
            selectedBox=-1;
            [self.delegate hiddenTextField:YES];
        }
        
    //no box selected
    }else{
        
        //locate if there is any box at the point touched
        selectedBox = [self whereIs:location];
        
//        if ((selectedBox != -1) && (![self boxIsVisible:[self.objects objectAtIndex:selectedBox]])) {
//            selectedBox = -1;
//            [self.delegate selectedAnObject:NO];
//        }
        
        if (selectedBox != -1) {
            [self.delegate hiddenTextField:NO];
            Box *currentBox=[self.objects objectAtIndex: selectedBox];
            [self.delegate selectedAnObject:YES];
            [currentBox setBounds:self.frame];

            [self.delegate stringLabel:currentBox.label];
            [self.delegate correctOrientation:currentBox.upperLeft :currentBox.lowerRight SuperviewFrame:self.frame];
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
        currentBox = [self.objects objectAtIndex:selectedBox];
        [currentBox updatePoints:firstLocation :location];        
    }
    
    else if (size){
        currentBox = [self.objects objectAtIndex:selectedBox];

        switch (corner) {
            case 1:
                corner+=[currentBox setUpperLeft:location];
                break;
            case 2:
                corner+=[currentBox setUpperLeft:CGPointMake([currentBox upperLeft].x, location.y)]-[currentBox setLowerRight:CGPointMake(location.x, [currentBox lowerRight].y)];
                break;
            case 3:
                corner+=[currentBox setUpperLeft:CGPointMake(location.x, [currentBox upperLeft].y)]-[currentBox setLowerRight:CGPointMake([currentBox lowerRight].x, location.y)];
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
    
    if (selectedBox != -1) {
        Box *currentBox =  [self.objects objectAtIndex: selectedBox];
        [self.delegate correctOrientation:currentBox.upperLeft :currentBox.lowerRight SuperviewFrame:self.frame];
        [self.delegate hiddenTextField:NO];
    }
    
    move = NO;
    size = NO;
    corner = -1;

    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Search Box

-(int)boxInterior:(int)i :(CGPoint)point
{

    int num = [self.objects count];
    for (int j=i+1; j<num; j++) {
        Box *newBox = [self.objects objectAtIndex: j];
       // [newBox setBounds:self.frame];

        if (CGRectContainsPoint( CGRectMake([newBox upperLeft].x-LINEWIDTH, [newBox upperLeft].y-LINEWIDTH, [newBox lowerRight].x-[newBox upperLeft].x+2*LINEWIDTH, [newBox lowerRight].y-[newBox upperLeft].y+2*LINEWIDTH),point)) {
            Box *currentBox = [self.objects objectAtIndex: i];
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

-(int)whereIs:(CGPoint) point
{
    int num = [self.objects count];
    
    for (int j=0; j<num; j++) {
        Box *newBox = [self.objects objectAtIndex: j];
        if (CGRectContainsPoint( CGRectMake([newBox upperLeft].x-LINEWIDTH, [newBox upperLeft].y-LINEWIDTH, [newBox lowerRight].x-[newBox upperLeft].x+2*LINEWIDTH, [newBox lowerRight].y-[newBox upperLeft].y+2*LINEWIDTH),point)) {
            return [self boxInterior:j :point];
        }
    }    
    return -1;  
}

#pragma mark -
#pragma mark Visible Box

-(void)setVisibleFrame:(CGRect)rect
{
    visibleFrame = rect;
}

-(CGRect)visibleFrame
{
    return visibleFrame;
}

//-(BOOL)boxIsVisible:(Box *)box
//{    
//    int num = 0;
//    if (CGRectContainsPoint(visibleFrame, box.upperLeft)) num++;
//    if (CGRectContainsPoint(visibleFrame, box.lowerRight)) num++;
//    if (CGRectContainsPoint(visibleFrame, CGPointMake(box.lowerRight.x, box.upperLeft.y))) num++;
//    if (CGRectContainsPoint(visibleFrame, CGPointMake(box.upperLeft.x, box.lowerRight.y))) num++;
//    
//    if(num > 1)return YES;
//    else return NO;
//}

#pragma mark -
#pragma mark Selected Box

-(void) setSelectedBox:(int) i
{

    selectedBox = i;
    if(i!=-1){
        Box *currentBox = [self.objects objectAtIndex: selectedBox];

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
    selectedBox = -1;
    [self.objects removeAllObjects];
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
    [Box setLINEWIDTH:LINEWIDTH];
    [self setNeedsDisplay];
}

- (BOOL) anyBoxSelected
{
    return selectedBox = -1 ? NO:YES;
}



@end
