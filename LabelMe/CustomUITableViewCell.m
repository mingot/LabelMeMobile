//
//  CustomUITableViewCell.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/06/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "CustomUITableViewCell.h"

#define kLeading 10.0


@implementation CustomUITableViewCell

@synthesize isEditable = _isEditable;


- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.contentView.frame;
    
    self.textLabel.frame = CGRectMake(0, 0, frame.size.width/4.0, frame.size.height);
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.size.width + frame.size.width/40.0, 0, (4.0/5.0)*frame.size.width, frame.size.height);
    
    if(self.isEditable){
        CGRect contentRect = self.contentView.bounds;
        CGSize textSize = [@"W" sizeWithFont: [[self textField] font]];
        //    self.textField.frame = self.detailTextLabel.frame;
        self.textField.frame = CGRectIntegral( CGRectMake(contentRect.size.width/3.0 + 5, (contentRect.size.height - textSize.height) / 2.0, (contentRect.size.width / 2.0) - (2.0 * kLeading), textSize.height) );
    }
    
}

- (BOOL) isEditable
{
    return _isEditable;
}

-(void)setIsEditable:(BOOL)isEditable
{
    _isEditable = isEditable;
    if(_isEditable){
        _textField = [[UITextField alloc] initWithFrame: CGRectZero];
        _textField.minimumFontSize = 12;
        _textField.adjustsFontSizeToFitWidth = YES;
        [self addSubview: _textField];
    }
}

@end

