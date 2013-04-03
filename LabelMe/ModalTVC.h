//
//  ModalTVC.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ModalTVCDelegate <NSObject>

- (void) selected:(NSArray *)selectedRows;

@end



@interface ModalTVC : UIViewController <UITableViewDelegate,UITableViewDataSource>


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) NSMutableArray *selectedItems;
@property (strong, nonatomic) id<ModalTVCDelegate> delegate;
@property BOOL multipleChoice;


- (IBAction)doneAction:(id)sender;

@end
