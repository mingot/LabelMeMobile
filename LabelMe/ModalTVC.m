//
//  ModalTVC.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "ModalTVC.h"


@implementation ModalTVC

@synthesize data = _data;
@synthesize selectedItems = _selectedItems;
@synthesize tableView = _tableView;
@synthesize delegate = _delegate;
@synthesize multipleChoice = _multipleChoice;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedItems = [[NSMutableArray alloc] init];
    
    self.doneButton.enabled = NO;
    self.doneButton.alpha = 0.6f;
}


#pragma mark
#pragma mark - TableView Delegate and Datasource

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];


    NSNumber *row = [NSNumber numberWithInt:indexPath.row];
    if([self.selectedItems indexOfObject:row] != NSNotFound) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.textLabel.text = [self.data objectAtIndex:indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *row = [NSNumber numberWithInt:indexPath.row];
    if([self.selectedItems indexOfObject:row] == NSNotFound){
        if(!self.multipleChoice) [self.selectedItems removeAllObjects];
        [self.selectedItems addObject:row];
    }
    else [self.selectedItems removeObject:row];
    
    //Enable done button when at list on item selected
    if(self.selectedItems.count!=0){
        self.doneButton.enabled = YES;
        self.doneButton.alpha = 1.0f;
    }else{
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6f;
    }
    
    
    
    [tableView reloadData];
}


- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setDoneButton:nil];
    [super viewDidUnload];
}


- (IBAction)doneAction:(id)sender
{
    NSLog(@"Done, selected items:");
    for(NSNumber *num in self.selectedItems)
        NSLog(@"%@", num);
    
    //send index of selected rows
    [self.delegate userSlection:[[NSArray alloc] initWithArray:self.selectedItems]];
    [self dismissModalViewControllerAnimated:YES];
}

@end
