//
//  ModalTVC.h
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AYUIButton.h"

@protocol ModalSectionsTVCDelegate <NSObject>

//set the items the user selected
- (void) userSlection:(NSArray *)selectedItems for:(NSString *)identifier;
- (void) selectionCancelled;

@end


@interface ModalSectionsTVC : UIViewController <UITableViewDelegate,UITableViewDataSource>

//model
@property (strong, nonatomic) NSDictionary *dataDictionary;//class->index (on thumbnailImages)
@property (strong, nonatomic) NSArray *thumbnailImages;

@property (strong, nonatomic) NSMutableArray *selectedItems;
@property (strong, nonatomic) id<ModalSectionsTVCDelegate> delegate;

@property (weak, nonatomic) IBOutlet AYUIButton *doneButton;
@property (weak, nonatomic) IBOutlet AYUIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *selectionLabel;

//unique name to identify the modal
@property (strong, nonatomic) NSString *modalTitle;
@property BOOL showCancelButton;


- (IBAction)doneAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)imageSelectedAction:(UIButton *)button;

//click the section name to select all the images of the section
- (IBAction)selectAllAction:(id)sender;

@end
