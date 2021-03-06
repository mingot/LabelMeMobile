//
//  ModalTVC.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ModalTVC.h"
#import "UIImage+Border.h"



#define NUMBER_IMAGE_COLUMNS 4.0

@interface ModalTVC()

@property BOOL isGrid;

- (void) toggleDoneButton;
- (void) setStateSelected:(BOOL) selected forCell:(ImageCell *)cell;

@end


@implementation ModalTVC


#pragma mark -
#pragma mark Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.doneButton highlightButton];
    [self.cancelButton highlightButton];
    
    self.tableView.layer.cornerRadius = 10;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    //TODO: Size for iPad!!
    [self.collectionView registerClass:[ImageCell class] forCellWithReuseIdentifier:@"cvCell"];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat imageSize = [UIScreen mainScreen].bounds.size.width/NUMBER_IMAGE_COLUMNS;
    [flowLayout setItemSize:CGSizeMake(imageSize, imageSize)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];    
    
    //TODO: in grid mode, no distinction between multiplechoice.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleLabel.text = self.modalTitle;
    self.subtitleLabel.text = self.modalSubtitle;
    if(!self.doneButtonTitle) self.doneButtonTitle = @"Done";
    [self.doneButton setTitle:self.doneButtonTitle forState:UIControlStateNormal];
    
    if(self.selectedItems.count == 0){
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6f;
    }
    self.cancelButton.hidden = !self.showCancelButton;
    
    //show images or text?
    self.isGrid = [[self.data objectAtIndex:0] isKindOfClass:[UIImage class]];
    self.collectionView.hidden = !self.isGrid;
    self.tableView.hidden = self.isGrid;
    
}

#pragma mark -
#pragma mark Getters and Setters

- (NSMutableArray *) selectedItems
{
    if(!_selectedItems) _selectedItems = [[NSMutableArray alloc] init];
    return _selectedItems;
}

- (void) setData:(NSArray *)data
{
    if(_data!=data){
        _data = data;
        [self.tableView reloadData];
        [self.collectionView reloadData];
    }
}


#pragma mark
#pragma mark - TableView Delegate and Datasource


- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{    
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellIdentifier = @"tvCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellIdentifier];
    
    NSNumber *row = [NSNumber numberWithInt:indexPath.row];
    if([self.selectedItems indexOfObject:row] != NSNotFound) cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else cell.accessoryType = UITableViewCellAccessoryNone;
    
    if(!self.isGrid) cell.textLabel.text = [self.data objectAtIndex:indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *row = [NSNumber numberWithInt:indexPath.row];
    if([self.selectedItems indexOfObject:row] == NSNotFound){
        if(!self.multipleChoice) [self.selectedItems removeAllObjects];
        [self.selectedItems addObject:row];
        
    }else [self.selectedItems removeObject:row];
    
    //Enable done button when at list on item selected
    [self toggleDoneButton];
    
    [tableView reloadData];
}

#pragma mark
#pragma mark - CollectionView Delegate and Datasource

//Data source

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{

    ImageCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"cvCell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor whiteColor];
    NSNumber *row = [NSNumber numberWithInt:indexPath.row];
    if([self.selectedItems indexOfObject:row] != NSNotFound){
        [self setStateSelected:YES forCell:cell];
    }else [self setStateSelected:NO forCell:cell];
    
    if(self.isGrid) cell.imageView.image = [self.data objectAtIndex:indexPath.row];
    return cell;
}


//Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *row = [NSNumber numberWithInt:indexPath.row];
    ImageCell *selectedCell = (ImageCell *) [collectionView cellForItemAtIndexPath:indexPath];
    if([self.selectedItems indexOfObject:row] == NSNotFound){
        [self.selectedItems addObject:row];
        [self setStateSelected:YES forCell:selectedCell];
    }else{
        [self.selectedItems removeObject:row];
        [self setStateSelected:NO forCell:selectedCell];
    }
}

#pragma mark 
#pragma mark - IBActions

- (IBAction)doneAction:(id)sender
{    
    //send index of selected rows
    [self.delegate userSlection:[[NSArray alloc] initWithArray:self.selectedItems] for:self.modalID];
    if(self.autodismiss)[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)cancelAction:(id)sender
{
    [self.delegate selectionCancelled];
    if(self.autodismiss)[self dismissModalViewControllerAnimated:YES];
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


- (void)viewDidUnload
{
    [self setCancelButton:nil];
    [self setTitleLabel:nil];
    [self setSubtitleLabel:nil];
    [self setCollectionView:nil];
    [super viewDidUnload];
}

- (void) setStateSelected:(BOOL) selected forCell:(ImageCell *) cell
{
    if(selected){
        cell.layer.borderWidth = 4;
        cell.layer.borderColor = [UIColor colorWithRed:160/256.0 green:32/256.0 blue:28/256.0 alpha:1].CGColor;
        cell.imageView.alpha = 0.5;
    }else{
        cell.layer.borderWidth = 0;
        cell.imageView.alpha = 1;
    }
    [cell setNeedsDisplay];
}

@end
