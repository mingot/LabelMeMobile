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


// GENERAL CASE when we have a UIScrollView

//- (void) keyboardDidShow:(NSNotification *)notif
//{
//    self.tagView.userInteractionEnabled = NO;
//    [self.scrollView setScrollEnabled:YES];
//    [self.labelsView setHidden:YES];
//    [self.labelsButton setSelected:NO];
//	if (keyboardVisible) return;
//
//	// Get the origin of the keyboard when it finishes animating
//	NSDictionary *info = [notif userInfo];
//	NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
//
//	// Get the top of the keyboard in view's coordinate system.
//	// We need to set the bottom of the scrollview to line up with it
//
//	CGRect keyboardRect = [aValue CGRectValue];
//    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
//	CGFloat keyboardTop = keyboardRect.origin.y;
//    CGRect viewFrame = self.scrollView.frame;
//	viewFrame.size.height = keyboardTop;
//
//	self.scrollView.frame = viewFrame;
//
////    [self.scrollView scrollRectToVisible:self.label.frame animated:YES];
//	keyboardVisible = YES;
//}
//
//- (void) keyboardDidHide:(NSNotification *)notif
//{
//    [self.scrollView setScrollEnabled:NO];
//
//	if (!keyboardVisible)
//		return;
//
//    self.scrollView.frame = CGRectMake(0,0, self.view.frame.size.width, self.view.frame.size.height-self.bottomToolbar.frame.size.height);
//
//	keyboardVisible = NO;
//    self.tagView.userInteractionEnabled=YES;
//}

