//
//  ShowTrainingSetViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 27/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "ShowTrainingSetViewController.h"


@implementation ShowTrainingSetViewController

@synthesize listOfImages = _listOfImages;
@synthesize tableView = _tableView;
@synthesize imageController = _imageController;


#pragma mark
#pragma mark Initialization and lifecycle

- (void)viewDidLoad
{
    self.imageController = [[ShowImageViewController alloc] initWithNibName:@"ShowImageViewController" bundle:nil];
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}



#pragma mark
#pragma mark TableView Delegate and Datasource

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return self.listOfImages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TrainingImagesCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.textLabel.text = [NSString stringWithFormat:@"Image%d", indexPath.row];
    cell.imageView.image = [self.listOfImages objectAtIndex:indexPath.row];
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.imageController.title = [NSString stringWithFormat:@"Image%d", indexPath.row];
    self.imageController.imageView.image = [self.listOfImages objectAtIndex:indexPath.row];
    self.imageController.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.navigationController pushViewController:self.imageController animated:YES];
}



@end
