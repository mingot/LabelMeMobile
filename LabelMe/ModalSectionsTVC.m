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

@property (nonatomic, strong) NSArray *labelsOrdered; //ordered labels names
@property (nonatomic, strong) NSMutableDictionary *buttonsDictionary; //buttons stored to select all images when section name tapped

- (void) toggleDoneButton;


@end


@implementation ModalSectionsTVC


#pragma mark
#pragma mark - Getters and setters

- (NSArray *) labelsOrdered
{
    if(!_labelsOrdered) _labelsOrdered = [[self.dataDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return _labelsOrdered;
}

- (NSMutableDictionary *) buttonsDictionary
{
    if(!_buttonsDictionary){
        
        _buttonsDictionary = [[NSMutableDictionary alloc] init];
        for (NSString *label in self.labelsOrdered){
            NSArray *indexes = [self.dataDictionary objectForKey:label];
            NSMutableArray *buttons = [[NSMutableArray alloc] init];
            for(int i=0; i<indexes.count; i++){
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.tag = [[indexes objectAtIndex:i] intValue];
                
                //button views generation
                UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width)];
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0.0375*self.view.frame.size.width,0.4125*self.view.frame.size.width, 0.4125*self.view.frame.size.width)];
                imageView.image = [self.thumbnailImages objectAtIndex:[[indexes objectAtIndex:i] intValue]];
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
            
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
                    button.frame = CGRectMake(0.05*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.225*self.view.frame.size.width, 0.225*self.view.frame.size.width);
                
                else button.frame = CGRectMake(0.07*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.2*self.view.frame.size.width, 0.2*self.view.frame.size.width);
                
                [button addTarget:self
                           action:@selector(imageSelectedAction:)
                 forControlEvents:UIControlEventTouchUpInside];
                [button setImage:image forState:UIControlStateNormal];
                [button setImage:[imageSelected addBorderForViewFrame:self.view.frame] forState:UIControlStateSelected];
                
                
                [buttons addObject:button];
            }
            [_buttonsDictionary setObject:buttons forKey:label];
        }
    }
    return _buttonsDictionary;
}


-(NSMutableArray *) selectedItems
{
    if(!_selectedItems) _selectedItems = [[NSMutableArray alloc] init];
    return _selectedItems;
}

#pragma mark
#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.selectedItems.count == 0){
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6f;
    }
    
    //round corners in the view
    [self.tableView.layer setCornerRadius:6.0];
    
    self.cancelButton.hidden = !self.showCancelButton;
}



#pragma mark
#pragma mark - TableView Delegate and Datasource

//modify view of the header to include a button to select all the pictures of the caregory
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 200)];
    [headerView setBackgroundColor:[UIColor blackColor]];
    
//    UIView *headerView = [tableView headerViewForSection:section];
    UIButton *selectAll = [[UIButton alloc] initWithFrame:CGRectMake(0,0,120,30 )];
    [selectAll setTitle:[self.labelsOrdered objectAtIndex:section] forState:UIControlStateNormal];
    selectAll.tag = section;
    [selectAll addTarget:self action:@selector(selectAllAction:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:selectAll];
    
    return headerView;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 50; //
//}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.labelsOrdered.count;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *label = [self.labelsOrdered objectAtIndex:section];
    NSArray *items = [self.dataDictionary objectForKey:label];
    return [NSString stringWithFormat:@"%@ (%d)",label,items.count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSArray *items = [self.dataDictionary objectForKey:[self.labelsOrdered objectAtIndex:indexPath.section]];
    return (0.225*self.view.frame.size.width*ceil((float)items.count/4) + 0.0375*self.view.frame.size.width);
}


- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    
    if (self.labelsOrdered.count>0) return 1;
    else return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    NSString *label = [self.labelsOrdered objectAtIndex:indexPath.section];
    NSMutableArray *buttons = [self.buttonsDictionary objectForKey:label];
    
    for(UIButton *button in buttons)
        [cell addSubview:button];
    
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


- (IBAction)cancelAction:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    [self.delegate selectionCancelled];
}

- (IBAction)imageSelectedAction:(UIButton *)button
{
    if(button.selected) [self.selectedItems removeObject:[NSNumber numberWithInt:button.tag]];
    else [self.selectedItems addObject:[NSNumber numberWithInt:button.tag]];
    
    button.selected = button.selected ? NO:YES;
    
    [self toggleDoneButton];
}


-(IBAction)selectAllAction:(id)sender
{
    UIButton *senderButton = (UIButton *)sender;
    NSString *label = [self.labelsOrdered objectAtIndex:senderButton.tag];
    NSArray *buttons = [self.buttonsDictionary objectForKey:label];
    
    for(UIButton *button in buttons)
        [self imageSelectedAction:button];
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
