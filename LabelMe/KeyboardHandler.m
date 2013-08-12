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
    UITextField *_textField;
    BOOL _moved;
    int _difference;
    UIToolbar *_toolbar; //word suggestion
}

@end


@implementation KeyboardHandler

#pragma mark -
#pragma mark Initialization

- (id)initWithTextField:(UITextField *)textField;
{
    if (self = [super init]) {
        _textField = textField;
        
        //toolbar for word suggestion
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        _toolbar.barStyle = UIBarStyleBlackOpaque;
        _textField.inputAccessoryView = _toolbar;

        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyPressed:) name: UITextFieldTextDidChangeNotification object: nil];
    }
    return self;
}



- (void)dealloc
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark Moving view

-(void)keyboardWillShow:(NSNotification *)notification
{
    // get the coordinates of the keyboard
    CGRect keyboardRect =[[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    // get the absolute coordinates of the view (inside UIWindow)
    CGPoint absoluteOrigin = [_textField convertPoint:_textField.frame.origin toView:nil];
    
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
    
    CGRect rect = _textField.frame;
    if(moveup) rect.origin.y += _difference;
    else rect.origin.y -= _difference;
    
    _textField.frame = rect;
    [UIView commitAnimations];
}


#pragma mark -
#pragma mark Word suggestion

-(void) keyPressed:(NSNotification *) notification
{
    
    UITextField *t = (UITextField *)[notification object];
    
    NSArray *words = [self.dataSource arrayOfWords];
    NSMutableArray *toolbarSuggestions = [[NSMutableArray alloc] initWithCapacity:words.count];
    
    for (NSString* word in words)
        if ([word hasPrefix:t.text])
            [toolbarSuggestions addObject:[[UIBarButtonItem alloc]initWithTitle:word style:UIBarButtonItemStyleBordered target:self action:@selector(setTextFieldText:)]];
    
    _toolbar.items = [NSArray arrayWithArray:toolbarSuggestions];
}

- (IBAction)setTextFieldText:(id)sender
{
    _textField.text = [(UIBarButtonItem *)sender title];
    
}


@end




