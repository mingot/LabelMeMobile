//
//  TagView.m
//  LabelMe_work
//
//  Created by David Way on 4/4/12.
//  Updated by Josep Marc Mingot.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//


#import "TagView.h"
#import "Constants.h"
#import "UITextField+BoxLabeling.h"
#import "NSString+checkValidity.h" //replacebyunderscore
#import "KeyboardHandler.h"


#define NO_BOX_SELECTED -1
#define kLineWidth 6
#define kLabelWidth 130
#define kLabelHeight 40
#define kLabelFontSize 15

#define kExteriorBox 0
#define kUpperLeft 1
#define kUpperRight 2
#define kLowerLeft 3
#define kLowerRight 4
#define kInteriorBox 5

#define kUIViewAutoresizingFlexibleHeighWidth   \
UIViewAutoresizingFlexibleWidth           | \
UIViewAutoresizingFlexibleHeight



@interface TagView()
{
    float _lineWidth;
    BOOL _touchIsMoving;
    BOOL _touchIsResizing;
}


- (int) whereIs:(CGPoint) point;
- (int) boxInterior:(int)i :(CGPoint)point;
- (void) drawBox:(Box *)box alpha:(CGFloat)alpha corners:(BOOL)hasCorners;

@end


@implementation TagView

@synthesize selectedBox = _selectedBox;

#pragma mark -
#pragma mark Initialization

- (void)initializeAndAddLabelView
{
    self.label = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, kLabelWidth, kLabelHeight)];
    [self.label setFont:[UIFont systemFontOfSize:kLabelFontSize]];
    [self.label initialSetup];
    [self.label setDelegate:self];
    [self.label setReturnKeyType:UIReturnKeyDone];
    [self.label addTarget:self
                   action:@selector(labelFinish:)
         forControlEvents:UIControlEventEditingDidEndOnExit];
    [self addSubview:self.label];
    
    
    //add suggestion toolbar
    //buttons settings
    UIBarButtonItem *a = [[UIBarButtonItem alloc]initWithTitle:@"Suggestion1" style:UIBarButtonItemStyleBordered target:self action:@selector(prova:)];
    UIBarButtonItem *b = [[UIBarButtonItem alloc]initWithTitle:@"Suggestion2" style:UIBarButtonItemStyleBordered target:self action:@selector(prova:)];
    UIBarButtonItem *c = [[UIBarButtonItem alloc]initWithTitle:@"Suggestion3" style:UIBarButtonItemStyleDone target:self action:@selector(prova:)];

    
    UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
    keyboardToolbar.barStyle = UIBarStyleBlackOpaque;
    keyboardToolbar.items = [NSArray arrayWithObjects:a,b, c,nil];
    self.label.inputAccessoryView = keyboardToolbar;
}

- (IBAction)prova:(id)sender
{
    UIBarButtonItem *b = (UIBarButtonItem *) sender;
    NSLog(@"prova with title:%@", b.title);
}

- (void) initialize
{
    [self setBackgroundColor:[UIColor clearColor]];
    
    _touchIsMoving = NO;
    _touchIsResizing = NO;

    _lineWidth = kLineWidth;
    
    [self initializeAndAddLabelView];
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
    _selectedBox = i;
    BOOL isBoxSelected = i != NO_BOX_SELECTED;
    if(isBoxSelected){
        Box *currentBox = [self.boxes objectAtIndex:_selectedBox];
        [self.label fitForBox:currentBox];
        self.label.text = currentBox.label;
    }
    
    self.label.hidden = !isBoxSelected;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"isBoxSelected" object:[NSNumber numberWithBool:isBoxSelected]];

    [self setNeedsDisplay];
}

-(int) selectedBox
{
    return _selectedBox;
}

#pragma mark -
#pragma mark Public Methods


- (void) setUpViewForZoomScale:(float)factor
{
    
    _lineWidth = kLineWidth / factor;
    
    CGRect labelFrame = self.label.frame;
    [self.label setFont:[UIFont systemFontOfSize:kLabelFontSize / factor]];
    labelFrame.size.width = kLabelWidth / factor;
    labelFrame.size.height = kLabelHeight / factor;
    self.label.frame = labelFrame;
    
    [self setNeedsDisplay];
}

- (void) setBoxes:(NSArray *) boxes
{
    if(boxes != _boxes){
        _boxes = boxes;
        self.selectedBox = NO_BOX_SELECTED;
        //ajust each box to the size of the TagViewFrame
        for(Box* box in _boxes)
            [box setBoxDimensionsForFrameSize:self.frame.size];
    }
    [self setNeedsDisplay];
}

- (void) addBox:(Box *)box
{
    NSMutableArray *boxes = [NSMutableArray arrayWithArray:self.boxes];
    [boxes addObject:box];
    _boxes = [NSArray arrayWithArray:boxes];
    self.selectedBox = boxes.count - 1;
    [self setNeedsDisplay];
}

- (void) addBoxInVisibleRect:(CGRect)visibleRect
{
    CGPoint newUpperLeft = CGPointMake(visibleRect.origin.x + 0.3*visibleRect.size.width, visibleRect.origin.y + 0.3*visibleRect.size.height);
    CGPoint newLowerRight = CGPointMake(visibleRect.origin.x + 0.7*visibleRect.size.width, visibleRect.origin.y + 0.7*visibleRect.size.height);
    
    Box *newBox = [[Box alloc] initWithUpperLeft:newUpperLeft lowerRight:newLowerRight forImageSize:self.frame.size];
    
    [self addBox:newBox];
}

- (void) removeSelectedBox
{
    if(self.selectedBox != NO_BOX_SELECTED){
        NSMutableArray *boxes = [NSMutableArray arrayWithArray:self.boxes];
        [boxes removeObjectAtIndex:self.selectedBox];
        _boxes = [NSArray arrayWithArray:boxes];
    }
    self.selectedBox = - 1;
    [self setNeedsDisplay];
}

- (Box *) getSelectedBox
{
    Box *selectedBox;
    
    if(self.selectedBox != NO_BOX_SELECTED)
        selectedBox = [self.boxes objectAtIndex:self.selectedBox];
    
    return selectedBox;
}


#pragma mark -
#pragma mark Draw Rect

- (void) drawRect:(CGRect)rect
{
    if (self.boxes.count<1)
        return;
   
    for(int i=0; i<self.boxes.count; i++){
        
        Box *box = [self.boxes objectAtIndex:i];
        box.lineWidth = _lineWidth;
        if(self.selectedBox == NO_BOX_SELECTED) [self drawBox:box alpha:1 corners:false];
        else if(self.selectedBox == i) [self drawBox:box alpha:1 corners:true];
        else [self drawBox:box alpha:0.3 corners:false];
                
    }
}


-(void) drawBox:(Box *)box alpha:(CGFloat)alpha corners:(BOOL)hasCorners
{
    CGContextRef context = UIGraphicsGetCurrentContext();
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
    
    //a box was previously selected
    if (self.selectedBox != NO_BOX_SELECTED) {
        Box *currentBox = [self.boxes objectAtIndex:self.selectedBox];

        int corner = [currentBox touchAtPoint:location];
        
        if(corner == kInteriorBox){
            _touchIsMoving = YES;
            [currentBox moveBeginAtPoint:location];
            
        }else if(corner == kExteriorBox){
            [self endEditing:YES];
            self.selectedBox = NO_BOX_SELECTED;
            
        }else{
            _touchIsResizing = YES;
            [currentBox resizeBeginAtPoint:location];
        }
        
    }else{
        
        //locate if there is any box at the point touched
        self.selectedBox = [self whereIs:location];
        
        if (self.selectedBox != NO_BOX_SELECTED) {

            Box *currentBox = [self.boxes objectAtIndex:self.selectedBox];
            currentBox.imageSize = self.frame.size;
            
            self.label.text = currentBox.label;
            [self.label fitForBox:currentBox];
            
        }
        
        _touchIsResizing = NO;
        _touchIsMoving = NO;
    }
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:touch.view];
    self.label.hidden = YES;
    
    if(self.selectedBox != NO_BOX_SELECTED){
        Box *currentBox = [self.boxes objectAtIndex:self.selectedBox];
        if (_touchIsMoving) [currentBox moveToPoint:location];
        else if (_touchIsResizing) [currentBox resizeToPoint:location];
    }
    
    [self setNeedsDisplay];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

    if ((_touchIsMoving) || (_touchIsResizing)) [self.delegate objectModified];
    
    if (self.selectedBox != NO_BOX_SELECTED) {
        Box *currentBox =  [self.boxes objectAtIndex: self.selectedBox];
        
        [self.label fitForBox:currentBox];
        self.label.hidden = NO;
    }
    
    _touchIsMoving = NO;
    _touchIsResizing = NO;

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
