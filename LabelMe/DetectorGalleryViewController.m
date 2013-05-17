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
                if([list indexOfObject:box.label] == NSNotFound)
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
    //load detectors and create directory if it does not exist
    NSString *detectorsPath = [self.userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"];
    self.detectors = [NSKeyedUnarchiver unarchiveObjectWithFile:detectorsPath];
    if(!self.detectors) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self.userPath stringByAppendingPathComponent:@"Detectors"] withIntermediateDirectories:YES attributes:nil error:nil];
        self.detectors = [[NSMutableArray alloc] init];
    }
    
    //view controller specifications and top toolbar setting
    UIImage *titleImage = [UIImage imageNamed:@"detectorsTitle.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    titleView.image = titleImage;
    [self.navigationItem setTitleView:titleView];
    
    
    self.editButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton buttonBarWithTitle:@"Edit" target:self action:@selector(edit:)]];
    self.navigationItem.rightBarButtonItem = self.editButton;
    UIBarButtonItem *plusButton = [[UIBarButtonItem alloc] initWithCustomView:[UIButton plusBarButtonWithTarget:self action:@selector(addDetector:)]];
    self.navigationItem.leftBarButtonItem = plusButton;
    self.detectorController = [[DetectorDescriptionViewController alloc] initWithNibName:@"DetectorDescriptionViewController" bundle:nil];
    
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
        
    }else{
        [super setEditing:YES animated:YES];
        [self.tableView setEditing:YES animated:YES];
        [button setTitle:@"Done" forState:UIControlStateNormal];
    }
    [self.tableView reloadData];
}

- (IBAction)addDetector:(id)sender
{
    _selectedRow = self.detectors;
    
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Class:%@ \nTraining Images: %d", [detector.targetClasses componentsJoinedByString:@"+"], detector.imagesUsedTraining.count];
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
        if(![NSKeyedArchiver archiveRootObject:self.detectors toFile:[self.userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"]])
            NSLog(@"Unable to save the classifiers");
        
    }else if (editingStyle == UITableViewCellEditingStyleInsert) {
        Classifier *newDetector = [[Classifier alloc] init];
        newDetector.name = @"New Detector";
        newDetector.targetClasses = [NSArray arrayWithObject:@"Not Set"];
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
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    //add or update detector
    if(_selectedRow < self.detectors.count) [self.detectors replaceObjectAtIndex:_selectedRow withObject:updatedDetector];
    else [self.detectors addObject:updatedDetector];

    NSLog(@"updating detector at position: %d", _selectedRow);
    if(![NSKeyedArchiver archiveRootObject:self.detectors toFile:[self.userPath stringByAppendingPathComponent:@"Detectors/detectors_list.pch"]]){
        NSLog(@"Unable to save the classifiers");
    }
    
    [self.tableView reloadData];
}


@end
