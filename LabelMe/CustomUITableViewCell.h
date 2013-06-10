//
//  CustomUITableViewCell.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/06/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

//Custom UITableVIewCell designed for Style UITableViewCellStyleValue2 that also
//lets you define if the field is editable


#import <UIKit/UIKit.h>

@interface CustomUITableViewCell : UITableViewCell

//editable cell properties
@property (nonatomic, strong) UITextField *textField;
@property BOOL isEditable;

@end