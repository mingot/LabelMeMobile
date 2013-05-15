//
//  ModalTVC.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AYUIButton.h"
#import "UIButton+CustomViews.h"

@protocol ModalTVCDelegate <NSObject>

//set the items the user selected
- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;

- (void) selectionCancelled;

@end


@interface ModalTVC : UIViewController <UITableViewDelegate,UITableViewDataSource>

//model
@property (strong, nonatomic) NSArray *data; //either NSStrings or UIImages

@property (strong, nonatomic) NSMutableArray *selectedItems; //indexes
@property (strong, nonatomic) id<ModalTVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet AYUIButton *doneButton;
@property (weak, nonatomic) IBOutlet AYUIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSString *doneButtonTitle;
//unique name to identify the modal
@property (strong, nonatomic) NSString *modalTitle;
@property BOOL multipleChoice;
@property BOOL showCancelButton;


- (IBAction)doneAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)imageSelectedAction:(UIButton *)button;


@end
