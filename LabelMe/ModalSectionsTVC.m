//
//  ModalTVC.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ModalSectionsTVC.h"
#import "UIImage+Border.h"

@interface ModalSectionsTVC()

- (void) toggleDoneButton;

@end


@implementation ModalSectionsTVC


-(NSMutableArray *) selectedItems
{
    if(!_selectedItems) _selectedItems = [[NSMutableArray alloc] init];
    return _selectedItems;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.selectedItems.count == 0){
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6f;
    }
    
    self.cancelButton.hidden = !self.showCancelButton;
}



#pragma mark
#pragma mark - TableView Delegate and Datasource

////modify view of the header to include a button to select all the pictures of the caregory
//- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
//    UIButton *selectAll = [[UIButton alloc] init];
//    [selectAll setTitle:@"Select All" forState:UIControlStateNormal];
//    selectAll.tag = section;
//    [headerView addSubview:selectAll];
//    
//    return headerView;
//}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    NSArray *labels = [self.dataDictionary allKeys];
    return labels.count;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{

    NSArray *labels = [[self.dataDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return [labels objectAtIndex:section];

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSArray *labels = [[self.dataDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *items = [self.dataDictionary objectForKey:[labels objectAtIndex:indexPath.section]];
    return (0.225*self.view.frame.size.width*ceil((float)items.count/4) + 0.0375*self.view.frame.size.width);

}


- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    
    NSArray *labels = [[self.dataDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    if (labels.count>0) return 1;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    //select images for section
    NSArray *labels = [[self.dataDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *items = [self.dataDictionary objectForKey:[labels objectAtIndex:indexPath.section]];
    
    for(int i = 0; i < items.count; i++) {
        @autoreleasepool {
            
            UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width)];
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0.0375*self.view.frame.size.width,0.4125*self.view.frame.size.width, 0.4125*self.view.frame.size.width)];
            imageView.image = [self.thumbnailImages objectAtIndex:[[items objectAtIndex:i] intValue]];
            [imview addSubview:imageView];
            
            //unselected image
            UIGraphicsBeginImageContext(CGSizeMake(0.45*self.view.frame.size.width,0.45*self.view.frame.size.width));
            [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            //selected image
            UIGraphicsBeginImageContext(CGSizeMake(0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width));
            imview.alpha = 0.65;
            [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *imageSelected = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
            NSUInteger index = [[items objectAtIndex:i] intValue];
            button.tag = index;
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                button.frame = CGRectMake(0.05*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.225*self.view.frame.size.width, 0.225*self.view.frame.size.width);
            
            else button.frame = CGRectMake(0.07*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.2*self.view.frame.size.width, 0.2*self.view.frame.size.width);
            
            //if the cell is a selected item
            if ([self.selectedItems indexOfObject:[NSNumber numberWithInt:i]] == NSNotFound)
                button.selected = NO;
            else button.selected = YES;
            
            [button addTarget:self
                       action:@selector(imageSelectedAction:)
             forControlEvents:UIControlEventTouchUpInside];
            [button setImage:image forState:UIControlStateNormal];
            [button setImage:[imageSelected addBorderForViewFrame:self.view.frame] forState:UIControlStateSelected];
            
            [cell addSubview:button];
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
    
}



#pragma mark
#pragma mark - IBActions

- (IBAction)doneAction:(id)sender
{
    //send index of selected rows
    [self.delegate userSlection:[[NSArray alloc] initWithArray:self.selectedItems] for:self.modalTitle];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)imageSelectedAction:(UIButton *)button
{
    if(button.selected) [self.selectedItems removeObject:[NSNumber numberWithInt:button.tag]];
    else [self.selectedItems addObject:[NSNumber numberWithInt:button.tag]];
    
    button.selected = button.selected ? NO:YES;
    
    [self toggleDoneButton];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    [self.delegate selectionCancelled];
}

#pragma mark
#pragma mark - Private methods


- (void) toggleDoneButton
{
    
    if(self.selectedItems.count!=0){
        self.doneButton.enabled = YES;
        self.doneButton.alpha = 1.0f;
    }else{
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6f;
    }
}


- (void)viewDidUnload {
    [self setCancelButton:nil];
    [super viewDidUnload];
}
@end
