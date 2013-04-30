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
@synthesize userPath = _userPath;
@synthesize username = _username;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Detector" image:nil tag:2];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"camera.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"cameraActive.png"]];
    }
    return self;
}


- (void)viewDidLoad
{
    //load detectors and create directory if it does not exist
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.userPath = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,self.username];
    NSString *detectorsPath = [self.userPath stringByAppendingPathComponent:@"Detectors/detectors02.pch"];
    self.detectors = [NSKeyedUnarchiver unarchiveObjectWithFile:detectorsPath];
    if(!self.detectors) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self.userPath stringByAppendingPathComponent:@"Detectors"] withIntermediateDirectories:YES attributes:nil error:nil];
        self.detectors = [[NSMutableArray alloc] init];
    }
    
    //view controller specifications and top toolbar setting
    self.title = @"Detectors";
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(edit:)];
    [self.navigationItem setRightBarButtonItem:editButton];
    UIBarButtonItem *plusButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDetector:)];
    self.navigationItem.leftBarButtonItem = plusButton;
    self.detectorController = [[DetectorDescriptionViewController alloc] initWithNibName:@"DetectorDescriptionViewController" bundle:nil];
    
    //navigation controller
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:150/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    
    [super viewDidLoad];
}


#pragma mark
#pragma mark - IBActions

- (IBAction) edit:(id)sender
{
    if(self.editing){
        [super setEditing:NO animated:NO];
        [self.tableView setEditing:NO animated:NO];
        [self.tableView reloadData];
        [self.navigationItem.leftBarButtonItem setTitle:@"Edit"];
        [self.navigationItem.leftBarButtonItem setStyle:UIBarButtonItemStylePlain];
        
    }else{
        [super setEditing:YES animated:YES];
        [self.tableView setEditing:YES animated:YES];
        [self.tableView reloadData];
        [self.navigationItem.leftBarButtonItem setTitle:@"Done"];
        [self.navigationItem.leftBarButtonItem setStyle:UIBarButtonItemStyleDone];
    }
}

- (IBAction)addDetector:(id)sender
{
    NSLog(@"Adding detector!!");
    
    Classifier *newDetector = [[Classifier alloc] init];
    newDetector.name = @"New Detector";
    newDetector.targetClass = @"Not Set";
    self.detectorController.hidesBottomBarWhenPushed = YES;
    self.detectorController.delegate = self;
    self.detectorController.svmClassifier = newDetector;
    self.detectorController.view = nil; //to reexecute viewDidLoad
    self.detectorController.userPath = self.userPath;
    [self.navigationController pushViewController:self.detectorController animated:YES];
    
}

#pragma mark
#pragma mark - TableView Delegate and Datasource

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
//    return self.editing ? self.detectors.count + 1 : self.detectors.count;
    return self.detectors.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    int count = 0;
    if(self.editing && indexPath.row != 0)
        count = 1;
    if(indexPath.row == ([self.detectors count]) && self.editing){
        cell.textLabel.text = @"Add Detector";
        return cell;
    }
    Classifier *detector = [self.detectors objectAtIndex:indexPath.row];
    cell.textLabel.text = detector.name;
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Class:%@ \nTraining Images: %d", detector.targetClass, detector.imagesUsedTraining.count];
    cell.imageView.image = [UIImage imageWithContentsOfFile:detector.averageImageThumbPath];
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView  editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing == NO || !indexPath) return UITableViewCellEditingStyleNone;
    
    if (self.editing && indexPath.row == ([self.detectors count]))
        return UITableViewCellEditingStyleInsert;
    else return UITableViewCellEditingStyleDelete;
    
    return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)aTableView  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.detectors removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
        if(![NSKeyedArchiver archiveRootObject:self.detectors toFile:[self.userPath stringByAppendingPathComponent:@"Detectors/detectors02.pch"]])
            NSLog(@"Unable to save the classifiers");
        
    }else if (editingStyle == UITableViewCellEditingStyleInsert) {
        Classifier *newDetector = [[Classifier alloc] init];
        newDetector.name = @"New Detector";
        newDetector.targetClass = @"Not Set";
        [self.detectors insertObject:newDetector atIndex:[self.detectors count]];
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
        _selectedRow = indexPath.row;
        self.detectorController.hidesBottomBarWhenPushed = YES;
        self.detectorController.delegate = self;
        self.detectorController.svmClassifier = [self.detectors objectAtIndex:indexPath.row];
        self.detectorController.view = nil; //to reexecute viewDidLoad
        self.detectorController.userPath = self.userPath;
        [self.navigationController pushViewController:self.detectorController animated:YES];
        
    }
}


#pragma mark
#pragma mark - Detector Description Delegate

- (void) updateDetector:(Classifier *)updatedDetector
{
    //update table
    [self.detectors addObject:updatedDetector];
    NSLog(@"updating detector at position: %d", _selectedRow);
    if(![NSKeyedArchiver archiveRootObject:self.detectors toFile:[self.userPath stringByAppendingPathComponent:@"Detectors/detectors02.pch"]]){
        NSLog(@"Unable to save the classifiers");
    }
    
    [self.tableView reloadData];
}


@end
