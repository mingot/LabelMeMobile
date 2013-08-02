//
//  KeyboardHandler.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 01/08/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "KeyboardHandler.h"

#define kOFFSET_FOR_KEYBOARD 20.0


@interface KeyboardHandler()
{
    UIView *_movingView;
    BOOL _moved;
    int _difference;
}

@end


@implementation KeyboardHandler

-(id) initWithView:(UIView *)movingView
{
    if (self = [super init]) {
        _movingView = movingView;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}


-(void)dealloc
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}



-(void)keyboardWillShow:(NSNotification *)notification
{
    // get the coordinates of the keyboard
    CGRect keyboardRect =[[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    // get the absolute coordinates of the view (inside UIWindow)
    CGPoint absoluteOrigin = [_movingView convertPoint:_movingView.frame.origin toView:nil];
    
    // if the keyboard is hidding it, move it up
    _difference = keyboardRect.origin.y - absoluteOrigin.y - kOFFSET_FOR_KEYBOARD;
    if (_difference < 0)
    {
        [self moveUp:YES];
        _moved = YES;
    }
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    // undo the move it the keyboard was hiding
    if (_moved) [self moveUp:NO];
}


- (void) moveUp:(BOOL)moveup
{
    // animate the sequence
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    CGRect rect = _movingView.frame;
    if(moveup) rect.origin.y += _difference;
    else rect.origin.y -= _difference;
    
    _movingView.frame = rect;
    [UIView commitAnimations];
}

@end
