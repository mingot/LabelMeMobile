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
#import "UIViewController+ShowAlert.h"


@interface DetectorGalleryViewController()
{
    NSInteger _selectedRow;
}

//detecotrs
@property (nonatomic, strong) NSMutableArray *detectors;
@property (nonatomic, strong) NSMutableArray *selectedItems;

//buttons
@property (strong, nonatomic) UIBarButtonItem *editButton;
@property (strong, nonatomic) UIButton *executeDetectorsButton;
@property (strong, nonatomic) UIBarButtonItem *plusButton;
@property (strong, nonatomic) UIBarButtonItem *deleteButton;
@property (strong, nonatomic) UIBarButtonItem *executeButton;


//top toolbar actions
- (IBAction) edit:(id)sender;
- (IBAction) addDetector:(id)sender;
- (IBAction) executeDetectorsAction:(id)sender;

//reload delete and execute buttons whenever needed
- (void) reloadToolbarButtons;

@end



@implementation DetectorGalleryViewController



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


- (void)initializeAndAddNoImagesView
{
    [self.noImages setBackgroundColor:[UIColor whiteColor]];
    self.noImages.layer.masksToBounds = YES;
    self.noImages.layer.cornerRadius = 10.0;
    self.noImages.layer.shadowColor = [UIColor grayColor].CGColor;
    self.noImages.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    self.noImages.shadowColor = [UIColor grayColor];
    self.noImages.numberOfLines = 3;
    self.noImages.shadowOffset = CGSizeMake(0.0, 1.0);
    self.noImages.text = @"You do not have detectors, \nstart training a detector";
    [self.noImages setTextAlignment:NSTextAlignmentCenter];
    [self.noImages setUserInteractionEnabled:YES];
    self.noImages.hidden = YES;
    [self.view addSubview:self.noImages];
}

- (void)initializeToolbarButtons
{
    UIImage *barButtonItem = [[UIImage imageNamed:@"barItemButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [[UIBarButtonItem appearance] setBackgroundImage:barButtonItem forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    
    //toolbar edit buttons
    self.deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteAction:)];
    [self.deleteButton setTintColor:[UIColor redColor]];
    [self.deleteButton setWidth:self.view.frame.size.width/2 - 11];
    [self.deleteButton setEnabled:NO];
    self.executeButton = [[UIBarButtonItem alloc] initWithTitle:@"Execute" style:UIBarButtonItemStyleBordered target:self action:@selector(executeDetectorsAction:)];
    [self.executeButton setWidth:self.view.frame.size.width/2 - 11];
    [self.executeButton setEnabled:NO];
    [self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
}

- (void)initializeNavigationBar
{
    //view controller specifications and top toolbar setting
    UIImage *titleImage = [UIImage imageNamed:@"detectorsTitle.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    titleView.image = titleImage;
    [self.navigationItem setTitleView:titleView];
    
    //navigationBarButtons
    self.editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = self.editButton;
    self.plusButton =[[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStylePlain target:self action:@selector(addDetector:)];
    [self.plusButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont boldSystemFontOfSize:20], UITextAttributeFont,nil] forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = self.plusButton;
    
    //solid color for the navigation bar
    [self.navigationController.navigationBar setBackgroundImage:[LMUINavigationController drawImageWithSolidColor:[UIColor redColor]] forBarMetrics:UIBarMetricsDefault];
}

- (void) initializeTableView
{
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    self.tableView.tableFooterView = customView;
}

- (void)viewDidLoad
{
    self.title = @"Detectors"; //for back button
    
    self.detectorResourceHandler = [[DetectorResourceHandler alloc] initForUsername:self.username];
    
    self.selectedItems = [[NSMutableArray alloc] init];
    self.detectors = [self.detectorResourceHandler loadDetectors];
        
    [self initializeTableView];
    [self initializeNavigationBar];
    [self initializeToolbarButtons];
    [self initializeAndAddNoImagesView];
    
    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
    if(self.detectors.count==0) self.noImages.hidden = NO;
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
    for(Detector *detector in aux) [self.detectors removeObject:detector];
    
    [self.selectedItems removeAllObjects];
    [self.tableView reloadData];
    
    [self.deleteButton setTitle:@"Delete"];
    self.deleteButton.enabled = NO;
    [self.executeButton setTitle:@"Execute"];
    self.executeButton.enabled = NO;
    
    //update detector list in disk
    [self.detectorResourceHandler saveDetectors:self.detectors];
    
    //delete images
    for(Detector *detector in aux)
        [self.detectorResourceHandler removeImageForDetector:detector];
    
    if(self.detectors.count==0) self.noImages.hidden = NO;
    
}



- (IBAction)addDetector:(id)sender
{
    _selectedRow = self.detectors.count;
    
    //check if there for no images or no labels to show error
    NSArray *availableObjectClasses = [self.detectorResourceHandler getObjectClassesNames];
    NSArray *availableTrainingImages = [self.detectorResourceHandler getTrainingImages];
    
    if(availableTrainingImages.count == 0) [self showAlertWithTitle:@"Empty" andDescription:@"No images to learn from"];
    else if(availableObjectClasses.count == 0) [self showAlertWithTitle:@"Empty" andDescription:@"No labels found"];
    else [self callDetectorDescriptionControllerWithDetctor:nil];
}

- (IBAction)executeDetectorsAction:(id)sender
{
    
    NSMutableArray *selectedDetectors = [[NSMutableArray alloc] init];
    for(NSNumber *index in self.selectedItems)
        [selectedDetectors addObject:[self.detectors objectAtIndex:index.intValue]];
    
    self.executeDetectorVC = [[ExecuteDetectorViewController alloc] init];
    self.executeDetectorVC.detectors = [NSArray arrayWithArray:selectedDetectors];
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
    Detector *detector = [reversedDetectors objectAtIndex:indexPath.row];
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
    CGFloat size = 80;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) size = 160;
    return size;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (self.editing == NO) {
        NSArray* reversedDetectors = [[self.detectors reverseObjectEnumerator] allObjects];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        _selectedRow = self.detectors.count - indexPath.row - 1;
        Detector *detector = [reversedDetectors objectAtIndex:indexPath.row];
        [self callDetectorDescriptionControllerWithDetctor:detector];
    
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

- (void) updateDetector:(Detector *)updatedDetector
{
    //add or update detector
    if(_selectedRow < self.detectors.count)
        [self.detectors replaceObjectAtIndex:_selectedRow withObject:updatedDetector];
    else [self.detectors addObject:updatedDetector];

    [self.detectorResourceHandler saveDetectors:self.detectors];
    
    [self.tableView reloadData];
    
    if(self.detectors.count>0) self.noImages.hidden = YES;
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

- (void) callDetectorDescriptionControllerWithDetctor:(Detector *)detector
{
    self.detectorController = [[DetectorDescriptionViewController alloc] initWithNibName:@"DetectorDescriptionViewController" bundle:nil];
    self.detectorController.hidesBottomBarWhenPushed = YES;
    self.detectorController.delegate = self;
    self.detectorController.detector = detector;
//    self.detectorController.view = nil; //to reexecute viewDidLoad
    self.detectorController.detectorResourceHandler = self.detectorResourceHandler;
    
    [self.navigationController pushViewController:self.detectorController animated:YES];
}

@end
