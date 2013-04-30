//
//  ModalTVC.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ModalTVCDelegate <NSObject>

//set the items the user selected
- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;

- (void) selectionCancelled;

@end


@interface ModalTVC : UIViewController <UITableViewDelegate,UITableViewDataSource>

//model
@property (strong, nonatomic) NSArray *data;


@property (strong, nonatomic) NSMutableArray *selectedItems;
@property (strong, nonatomic) id<ModalTVCDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//unique name to identify the modal
@property (strong, nonatomic) NSString *modalTitle;
@property BOOL multipleChoice;
@property BOOL showCancelButton;


- (IBAction)doneAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)imageSelectedAction:(UIButton *)button;


@end
