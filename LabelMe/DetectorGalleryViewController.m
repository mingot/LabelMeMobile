//
//  DetectorGalleryViewController.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 22/03/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "DetectorGalleryViewController.h"
#import "Box.h"


#import "LMUINavigationController.h"
#import "UIButton+CustomViews.h"

#define IMAGES 0
#define THUMB 1
#define OBJECTS 2
#define DETECTORS 3

@interface DetectorGalleryViewController()

//reload delete and execute buttons whenever needed
- (void) reloadToolbarButtons;

@end



@implementation DetectorGalleryViewController


@synthesize detectors = _detectors;
@synthesize tableView = _tableView;
@synthesize detectorController = _detectorController;
@synthesize username = _username;
@synthesize resourcesPaths = _resourcesPaths;
@synthesize availableObjectClasses = _availableObjectClasses;
@synthesize userPath = _userPath;



#pragma mark
#pragma mark - Setters and Getters

- (NSString *) userPath
{
    if(!_userPath){
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _userPath = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,self.username];
    }
    
    return _userPath;
}

-(NSArray *) resourcesPaths
{
    if(!_resourcesPaths){
        _resourcesPaths = [NSArray arrayWithObjects:
                               [self.userPath stringByAppendingPathComponent:@"images"],
                               [self.userPath stringByAppendingPathComponent:@"thumbnail"],
                               [self.userPath stringByAppendingPathComponent:@"annotations"],
                               [self.userPath stringByAppendingPathComponent:@"Detectors"],
                               self.userPath, nil];
    }
    
    return _resourcesPaths;
}


-(NSArray *) availableObjectClasses
{
    if(!_availableObjectClasses){
        NSMutableArray *list = [[NSMutableArray alloc] init];
        
        
        NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@",[self.resourcesPaths objectAtIndex:THUMB]] error:NULL];
        
        for(NSString *imageName in imagesList){
            NSString *path = [[self.resourcesPaths objectAtIndex:OBJECTS] stringByAppendingPathComponent:imageName];
            NSMutableArray *objects = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithFile:path]];
            for(Box *box in objects)
                if([list indexOfObject:box.label] == NSNotFound && ![box.label isEqualToString:@""])
                    [list addObject:box.label];
        }
        
        _availableObjectClasses = [NSArray arrayWithArray:list];
    }
    
    return _availableObjectClasses;
}

#pragma mark
#pragma mark -  Initialization and lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Detector" image:nil tag:2];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"detectorIcon.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"detectorsDisabled.png"]];
    }
    return self;
}


- (void)viewDidLoad
{
    self.title = @"Detectors"; //for back button
    
    //load detectors and create directory if it does not exist
    NSString *detectorsPath = [self.userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"];
    self.detectors = [NSKeyedUnarchiver unarchiveObjectWithFile:detectorsPath];
    if(!self.detectors) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self.userPath stringByAppendingPathComponent:@"Detectors"] withIntermediateDirectories:YES attributes:nil error:nil];
        self.detectors = [[NSMutableArray alloc] init];
    }
    
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    self.tableView.tableFooterView = customView;
    
    
    //view controller specifications and top toolbar setting
    UIImage *titleImage = [UIImage imageNamed:@"detectorsTitle.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    titleView.image = titleImage;
    [self.navigationItem setTitleView:titleView];
    
    
    self.editButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton buttonBarWithTitle:@"Edit" target:self action:@selector(edit:)]];
    self.navigationItem.rightBarButtonItem = self.editButton;
    self.plusButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton plusBarButtonWithTarget:self action:@selector(addDetector:)]];
    self.navigationItem.leftBarButtonItem = self.plusButton;
    self.detectorController = [[DetectorDescriptionViewController alloc] initWithNibName:@"DetectorDescriptionViewController" bundle:nil];
    
    //toolbar edit buttons
    self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteAction:)];
    [self.deleteButton setTintColor:[UIColor redColor]];
    [self.deleteButton setWidth:self.view.frame.size.width/2 - 11];
    [self.deleteButton setEnabled:NO];
    self.executeButton = [[UIBarButtonItem alloc] initWithTitle:@"Execute" style:UIBarButtonItemStyleBordered target:self action:@selector(executeDetectorsAction:)];
    [self.executeButton setWidth:self.view.frame.size.width/2 - 11];
    [self.executeButton setEnabled:NO];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
    self.selectedItems = [[NSMutableArray alloc] init];
    
    
    
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
    //solid color for the navigation bar
    [self.navigationController.navigationBar setBackgroundImage:[LMUINavigationController drawImageWithSolidColor:[UIColor redColor]] forBarMetrics:UIBarMetricsDefault];
}


#pragma mark
#pragma mark - IBActions

- (IBAction) edit:(id)sender
{
    UIButton *button = [self.editButton valueForKey:@"view"];
    
    if(self.editing){
        [super setEditing:NO animated:NO];
        [self.tableView setEditing:NO animated:NO];
        [button setTitle:@"Edit" forState:UIControlStateNormal];
        self.navigationItem.leftBarButtonItem = self.plusButton;
        
        [self.navigationController setToolbarHidden:YES];

        
    }else{
        [super setEditing:YES animated:YES];
        [button setTitle:@"Done" forState:UIControlStateNormal];
        self.navigationItem.leftBarButtonItem = nil;
        
        [self.navigationController setToolbarHidden:NO];
        NSArray *toolbarItems = [[NSArray alloc] initWithObjects:self.executeButton,self.deleteButton, nil];
        [self.navigationController.toolbar setItems:toolbarItems];
        

    }
    [self.tableView reloadData];
}

- (IBAction)deleteAction:(id)sender
{
    
    //delete from the model
    NSMutableArray *aux = [[NSMutableArray alloc] init];
    for(NSNumber *index in self.selectedItems) [aux addObject:[self.detectors objectAtIndex:index.intValue]];
    for(Classifier *classifier in aux) [self.detectors removeObject:classifier];
    
    [self.selectedItems removeAllObjects];
    [self.tableView reloadData];
    
    [self.deleteButton setTitle:@"Delete"];
    self.deleteButton.enabled = NO;
    [self.executeButton setTitle:@"Execute"];
    self.executeButton.enabled = NO;
    
    //update classifier list in disk
    if(![NSKeyedArchiver archiveRootObject:self.detectors toFile:[self.userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"]])
        NSLog(@"Unable to save the classifiers");
    
    //delete images
    for(Classifier *classifier in aux){
        NSString *bigImagePath = [self.userPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Detectors/%@_big.jpg", classifier.classifierID]];
        NSString *thumbnailImagePath = [self.userPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Detectors/%@_thumb.jpg", classifier.classifierID]];
        [[NSFileManager defaultManager] removeItemAtPath:bigImagePath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:thumbnailImagePath error:nil];
    }
    
}



- (IBAction)addDetector:(id)sender
{
    _selectedRow = self.detectors.count;
    
    //check if there for no images or no labels to show error
    self.availableObjectClasses = nil; //reload
    NSArray *imagesList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self.userPath stringByAppendingPathComponent:@"thumbnail"] error:NULL];
    
    if(imagesList.count == 0){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Empty"
                                                             message:@"No images to learn from"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [errorAlert show];
        return;
        
    }else if(self.availableObjectClasses.count == 0){
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Empty"
                                                             message:@"No labels found"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
        [errorAlert show];
        return;
    }
        
    Classifier *newDetector = [[Classifier alloc] init];
    newDetector.name = @"New Detector";
    newDetector.targetClasses = [NSArray arrayWithObject:@"Not Set"];
    self.detectorController.availableObjectClasses = self.availableObjectClasses;
    self.detectorController.hidesBottomBarWhenPushed = YES;
    self.detectorController.delegate = self;
    self.detectorController.svmClassifier = newDetector;
    self.detectorController.view = nil; //to reexecute viewDidLoad
    self.detectorController.userPath = self.userPath;
    [self.navigationController pushViewController:self.detectorController animated:YES];
    
    
}

- (IBAction)executeDetectorsAction:(id)sender
{
    
    NSMutableArray *selectedDetectors = [[NSMutableArray alloc] init];
    for(NSNumber *index in self.selectedItems)
        [selectedDetectors addObject:[self.detectors objectAtIndex:index.intValue]];
    
    self.executeDetectorVC = [[ExecuteDetectorViewController alloc] init];
    self.executeDetectorVC.svmClassifiers = [NSArray arrayWithArray:selectedDetectors];
    self.executeDetectorVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:self.executeDetectorVC animated:NO];
    
    //reload views
    [self edit:self];
    [self.selectedItems removeAllObjects];
    [self reloadToolbarButtons];
}



#pragma mark
#pragma mark - TableView Delegate and Datasource

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    return self.detectors.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    static NSString *CellIdentifier = @"detectorCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if(self.editing) cell.accessoryType = UITableViewCellAccessoryNone;
    else cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSArray* reversedDetectors = [[self.detectors reverseObjectEnumerator] allObjects]; //reverse order to show newer first
    Classifier *detector = [reversedDetectors objectAtIndex:indexPath.row];
    cell.textLabel.text = detector.name;
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Class:%@ \nTraining Images: %d", [detector.targetClasses componentsJoinedByString:@", "], detector.imagesUsedTraining.count];
    cell.imageView.image = [UIImage imageWithContentsOfFile:detector.averageImageThumbPath];
    
    //cell checkmarked when selected
    if([self.selectedItems containsObject:[NSNumber numberWithInt:self.detectors.count - indexPath.row - 1]] && self.editing)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.editing == NO) {
        NSArray* reversedDetectors = [[self.detectors reverseObjectEnumerator] allObjects];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        _selectedRow = self.detectors.count - indexPath.row - 1;
        self.detectorController.hidesBottomBarWhenPushed = YES;
        self.detectorController.delegate = self;
        self.detectorController.svmClassifier = [reversedDetectors objectAtIndex:indexPath.row];
        self.detectorController.view = nil; //to reexecute viewDidLoad
        self.detectorController.userPath = self.userPath;
        [self.navigationController pushViewController:self.detectorController animated:YES];
    
    }else{
        NSNumber *index = [NSNumber numberWithInt:self.detectors.count - indexPath.row - 1]; //index according to reversed order
        if(![self.selectedItems containsObject:index]) [self.selectedItems addObject:index];
        else [self.selectedItems removeObject:index];
        
        [self reloadToolbarButtons];
        [tableView reloadData];
    }
}


#pragma mark
#pragma mark - Detector Description Delegate

- (void) updateClassifier:(Classifier *)updatedDetector
{
    //add or update detector
    if(_selectedRow < self.detectors.count) [self.detectors replaceObjectAtIndex:_selectedRow withObject:updatedDetector];
    else [self.detectors addObject:updatedDetector];

    if(![NSKeyedArchiver archiveRootObject:self.detectors toFile:[self.userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"]]){
        NSLog(@"Unable to save the classifiers");
    }
    
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Private methods

- (void) reloadToolbarButtons
{
    
    if(self.selectedItems.count == 0){
        [self.deleteButton setTitle:@"Delete"];
        [self.executeButton setTitle:@"Execute"];
    }else{
        [self.deleteButton setTitle:[NSString stringWithFormat:@"Delete (%d)", self.selectedItems.count]];
        [self.executeButton setTitle:[NSString stringWithFormat:@"Execute (%d)", self.selectedItems.count]];
    }
    self.deleteButton.enabled = self.selectedItems.count > 0 ? YES:NO;
    self.executeButton.enabled = self.selectedItems.count > 0 ? YES:NO;

}

@end
