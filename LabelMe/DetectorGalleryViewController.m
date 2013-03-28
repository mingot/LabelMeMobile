//
//  DetectorGalleryViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorGalleryViewController.h"




#pragma mark
#pragma mark -  Initialization and lifecycle

@implementation DetectorGalleryViewController

@synthesize detectors = _detectors;
@synthesize tableView = _tableView;
@synthesize detectorController = _detectorController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Detector" image:nil tag:2];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"settings.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"settingsActive.png"]];
        
    }
    return self;
}


- (void)viewDidLoad
{
    self.detectors = [[NSMutableArray alloc] initWithObjects:@"car",@"bottle",@"cat",nil];
    self.title = @"Detectors Gallery";
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(Edit:)];
    [self.navigationItem setLeftBarButtonItem:addButton];
    self.detectorController = [[DetectorDescriptionViewController alloc]initWithNibName:@"DetectorDescriptionViewController" bundle:nil];
    
    
    [super viewDidLoad];
}


#pragma mark
#pragma mark - TableView Delegate and Datasource



- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return self.editing ? self.detectors.count +1 : self.detectors.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    int count = 0;
    if(self.editing && indexPath.row != 0)
        count = 1;
    if(indexPath.row == ([self.detectors count]) && self.editing){
        cell.textLabel.text = @"Add Data";
        return cell;
    }
    cell.textLabel.text = [self.detectors objectAtIndex:indexPath.row];
    return cell;
}

- (IBAction)AddButtonAction:(id)sender
{
    [self.detectors addObject:@"SaturDay"];
    [self.tableView reloadData];
}

- (IBAction)DeleteButtonAction:(id)sender
{
    [self.detectors removeLastObject];
    [self.tableView reloadData];
}

- (IBAction) Edit:(id)sender
{
    if(self.editing)
    {
        [super setEditing:NO animated:NO];
        [self.tableView setEditing:NO animated:NO];
        [self.tableView reloadData];
        [self.navigationItem.leftBarButtonItem setTitle:@"Edit"];
        [self.navigationItem.leftBarButtonItem setStyle:UIBarButtonItemStylePlain];
    }
    else
    {
        [super setEditing:YES animated:YES];
        [self.tableView setEditing:YES animated:YES];
        [self.tableView reloadData];
        [self.navigationItem.leftBarButtonItem setTitle:@"Done"];
        [self.navigationItem.leftBarButtonItem setStyle:UIBarButtonItemStyleDone];
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView  editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing == NO || !indexPath) return   UITableViewCellEditingStyleNone;
    if (self.editing && indexPath.row == ([self.detectors count])) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)aTableView  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.detectors removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self.detectors insertObject:@"SaturDay" atIndex:[self.detectors count]];
        [self.tableView reloadData];
    }
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView  moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath
{
    NSString *item = [self.detectors objectAtIndex:fromIndexPath.row];
    [self.detectors removeObject:item];
    [self.detectors insertObject:item atIndex:toIndexPath.row];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing == NO) {
        self.detectorController.title = [self.detectors objectAtIndex:indexPath.row];
        self.detectorController.classifierName = self.detectorController.title;
        self.detectorController.classToLearn = self.detectorController.title;
        self.detectorController.view = nil; //to reexecute viewDidLoad
        [self.navigationController pushViewController:self.detectorController animated:YES];
        
    }
}



- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}




@end
