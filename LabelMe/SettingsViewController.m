//
//  SettingsViewController.m
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "SettingsViewController.h"
#import "NSObject+Folders.h"
#import "Constants.h"
#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>
#import "ResolutionViewController.h"
#import "ServerConnection.h"
#import "CreditsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController
@synthesize tableView = _tableView;
@synthesize username = _username;
@synthesize popover = _popover;
@synthesize website = _website;

#pragma mark - Initialitation
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:nil tag:3];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"settings.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"settingsActive.png"]];
        self.username = [[NSString alloc] init];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            CGRect screenSize = [[UIScreen mainScreen] bounds];
            
            if (screenSize.size.height == 568) {
                self.website = [[WebsiteViewController alloc] initWithNibName:@"WebsiteViewController_iPhone5" bundle:nil];
                
            }
            else if (screenSize.size.height == 480){
                self.website = [[WebsiteViewController alloc] initWithNibName:@"WebsiteViewController_iPhone" bundle:nil];
                
            }
        }else{
            self.website = [[WebsiteViewController alloc] initWithNibName:@"WebsiteViewController_iPad" bundle:nil];
            
        }
    }
    return self;
}
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    //self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(self.topToolBar.frame.origin.x , self.topToolBar.frame.origin.y + self.topToolBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.topToolBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    UIBarButtonItem * logoutButton = [[UIBarButtonItem alloc]initWithTitle:@"Log out" style:UIBarButtonItemStyleBordered target:self action:@selector(logOutAction:)];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbarBg"]resizableImageWithCapInsets:UIEdgeInsetsZero  ] forBarMetrics:UIBarMetricsDefault];
    //[logoutButton setTintColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    [logoutButton setStyle:UIBarButtonItemStyleBordered];
    [self.navigationItem setRightBarButtonItem:logoutButton];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:150/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //self.view.backgroundColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1.0];
    //self.view.backgroundColor = [UIColor colorWithRed:(236/255.0) green:(32/255.0) blue:(28/255.0) alpha:1.0];
   // self.tableView.backgroundColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1.0];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:nil];

    [self setTitle:@"Settings"];
    

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [self.tableView reloadData];

}
#pragma mark - IBActions

-(IBAction)logOutAction:(id)sender
{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    if([filemng removeItemAtPath:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"] error:NULL]){
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(IBAction)profilePictureAction:(id)sender
{
    UIButton *button = (UIButton *) sender;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *photoSourceSheet = [[UIActionSheet
                                            alloc] initWithTitle:@"" delegate:self
                                           cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Photo"
                                           otherButtonTitles:@"Choose Existing Photo", @"Take Photo",  nil];
        [photoSourceSheet showFromTabBar:self.tabBarController.tabBar];
    }
    else { // No camera, just use the library.
        UIActionSheet *photoSourceSheet = [[UIActionSheet
                                            alloc] initWithTitle:@"" delegate:self
                                           cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Photo"
                                           otherButtonTitles: @"Choose Existing Photo",  nil];
        //[photoSourceSheet showFromTabBar:self.tabBarController.tabBar];
        [photoSourceSheet showFromRect:button.frame inView:self.view animated:YES];

        
    }

}


-(IBAction)valueDidChange:(id)sender
{
    NSArray *paths = [self newArrayWithFolders:self.username];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *dictnum = nil;
    UISwitch *sw = (UISwitch *)sender;
    if (sw.tag != 1) {
        dictnum = [NSNumber numberWithBool:[sw isOn]];
        switch (sw.tag) {
            case 0:
                [dict removeObjectForKey:@"cameraroll"];
                [dict setObject:dictnum forKey:@"cameraroll"];
                break;
            case 2:
                [dict removeObjectForKey:@"wifi"];
                [dict setObject:dictnum forKey:@"wifi"];
                break;
            case 3:
                [dict removeObjectForKey:@"signinauto"];
                [dict setObject:dictnum forKey:@"signinauto"];
                break;
                
            default:
                break;
        }
    }
    else{
        UISlider *slider = (UISlider *)sender;
        dictnum = [NSNumber numberWithFloat:[slider value]];
        [dict removeObjectForKey:@"resolution"];
        [dict setObject:dictnum forKey:@"resolution"];
    
    }
    [dict writeToFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"] atomically:NO];
    //[paths release];
}



#pragma mark - UIActionSheetDelegate methods

- (void) actionSheet:(UIActionSheet * ) actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
        
    }else if (buttonIndex == actionSheet.destructiveButtonIndex){
        NSFileManager * filemng = [NSFileManager defaultManager];
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

        if ([filemng fileExistsAtPath:[[documentsDirectory stringByAppendingPathComponent:self.username] stringByAppendingPathComponent:@"profilepicture.jpg" ]]) {
            [filemng removeItemAtPath:[[documentsDirectory stringByAppendingPathComponent:self.username] stringByAppendingPathComponent:@"profilepicture.jpg" ] error:NULL];
        }
        [self.tableView reloadData];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc]
                                       init];
    
    picker.delegate = self;
    //picker.allowsEditing = YES;
    switch (buttonIndex) {
        case 1:
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
            
        case 2:
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [picker setCameraDevice:UIImagePickerControllerCameraDeviceFront];
            break;
            
        default:
            break;
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            if ([self.popover isPopoverVisible]) {
                [self.popover dismissPopoverAnimated:YES];
                
            }else{
                UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
                [popover presentPopoverFromRect:actionSheet.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                
                self.popover = popover;
            }

        }else{
            [self presentViewController:picker animated:YES completion:NULL];
        }
        
    }else{
        [self presentViewController:picker animated:YES completion:NULL];

    }
}



#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.username] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    UIImage *img = (UIImage * )[info objectForKey:UIImagePickerControllerOriginalImage];
    if ([filemng createFileAtPath:path contents:UIImageJPEGRepresentation([img thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil]) {
        ServerConnection *sConnection = [[ServerConnection alloc]init];
        [sConnection uploadProfilePicture:[img thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh]];
    }
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);

    }
    [self.tableView reloadData];
    [picker dismissViewControllerAnimated:NO completion:NULL];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark TableView Delegate&Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    NSInteger ret = 0;
    switch (section) {
        
            
        case 3:
            ret = 4;
            break;
            
    
        default:
            ret = 1;
            break;
    }
    
    return ret;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString * ret = [[NSString alloc] init];
    if (section == 3) {
        ret = @"Advanced settings";
    }
    return  ret;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
         return  self.view.frame.size.width/2;
    }
    else{
        return tableView.rowHeight;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil) {
        return nil;
    }
    
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 6, 300, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    //label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor grayColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.text = sectionTitle;
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
//    [view autorelease];
    [view addSubview:label];
    
    return view;
}
   

   


- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
   /* static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    //
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }*/
    
    NSFileManager *filemng = [NSFileManager defaultManager];
    NSArray *paths = [self newArrayWithFolders:self.username];
    UITableViewCell *cell = nil;

    if (indexPath.section == 0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        UIButton *profilePictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell.imageView setBackgroundColor:[UIColor clearColor]];
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
        if (![filemng fileExistsAtPath:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]]) {
            
            [cell.imageView setImage:[UIImage imageNamed:@"silueta.png"]];
        }
        else{
            [cell.imageView  setImage:[UIImage imageWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]] ];

            
        }
        [profilePictureButton setFrame:CGRectMake(0.0625*self.view.frame.size.width, 0.03125*self.view.frame.size.width, self.view.frame.size.width/2,  self.view.frame.size.width/2)];
        [profilePictureButton addTarget:self action:@selector(profilePictureAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:profilePictureButton];
        [cell.textLabel setText:self.username];

    }
    else if (indexPath.section == 1){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        NSNumber *numberfiles =[NSNumber numberWithInteger: [[filemng contentsOfDirectoryAtPath:[paths objectAtIndex:THUMB] error:NULL] count]];
        
        [cell.textLabel setText:@"Number of images: "];
        [cell.detailTextLabel setText:numberfiles.stringValue];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    }
    else if (indexPath.section == 2){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        
        [cell.textLabel setText:@"Go to LabelMe Website"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    }
    else if (indexPath.section == 3){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
        [sw setOnTintColor:[UIColor colorWithRed:(180.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0]];


        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
        NSNumber *dictnum = nil;
        switch (indexPath.row) {

            case 0:
                [cell.textLabel setText:@"Save to library:"];
                dictnum = [dict objectForKey:@"cameraroll"];
                [sw setOn:[dictnum boolValue]  animated:NO];
                [sw setTag:0];
                [sw addTarget:self action:@selector(valueDidChange:) forControlEvents:UIControlEventValueChanged];
                [cell setAccessoryView:sw];
                
                break;
            case 1:
                [cell.textLabel setText:@"Image resolution"];
               /* dictnum = [dict objectForKey:@"resolution"];
                UISlider *slider = [[[UISlider alloc] initWithFrame:CGRectMake(0, 0, 100, [tableView rowHeight])]autorelease];
                [slider setMaximumValue:1.0];
                [slider setMinimumValue:0.01];
                [slider setMinimumTrackTintColor:[UIColor colorWithRed:(237.0/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0]];
                [slider setValue:[dictnum floatValue] animated:NO];
                [slider setTag:1];
                [slider addTarget:self action:@selector(valueDidChange:) forControlEvents:UIControlEventValueChanged];
                [cell setAccessoryView:slider];*/
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                break;
                
            case 2:
                [cell.textLabel setText:@"Wi-Fi only:"];
                dictnum = [dict objectForKey:@"wifi"];
                [sw setOn:[dictnum boolValue]  animated:NO];
                [sw addTarget:self action:@selector(valueDidChange:) forControlEvents:UIControlEventValueChanged];
                [sw setTag:2];
                [cell setAccessoryView:sw];
                break;
                
            case 3:
                [cell.textLabel setText:@"Sign in automatically:"];
                dictnum = [dict objectForKey:@"signinauto"];
                [sw setOn:[dictnum boolValue]  animated:NO];
                [sw addTarget:self action:@selector(valueDidChange:) forControlEvents:UIControlEventValueChanged];
                [sw setTag:3];
                [cell setAccessoryView:sw];
                break;
                
    
            default:
                break;
        }
    }
    else if (indexPath.section == 4){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        
        [cell.textLabel setText:@"About LabelMe"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    }

    
    // Configure the cell...
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    //[paths release];
        return cell;

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 2) {
               [self.website setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:self.website animated:YES];
    }
    else if ((indexPath.section == 3) && (indexPath.row == 1)) {
        ResolutionViewController *resolution = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            CGRect screenSize = [[UIScreen mainScreen] bounds];
            
            if (screenSize.size.height == 568) {
                resolution = [[ResolutionViewController alloc] initWithNibName:@"ResolutionViewController_iPhone5" bundle:nil];

                
                
            }
            else if (screenSize.size.height == 480){
                resolution = [[ResolutionViewController alloc] initWithNibName:@"ResolutionViewController_iPhone" bundle:nil];

                
                
            }
            
            
            
        }
        else{
            resolution = [[ResolutionViewController alloc] initWithNibName:@"ResolutionViewController_iPad" bundle:nil];

        }

        [resolution setUsername:self.username];
        [self.navigationController pushViewController:resolution animated:YES];
    }
    else if ((indexPath.section == 4) ) {
        CreditsViewController *credits = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            CGRect screenSize = [[UIScreen mainScreen] bounds];
            
            if (screenSize.size.height == 568) {
                credits = [[CreditsViewController alloc] initWithNibName:@"CreditsViewController_iPhone5" bundle:nil];
                
                
                
            }
            else if (screenSize.size.height == 480){
                credits = [[CreditsViewController alloc] initWithNibName:@"CreditsViewController_iPhone" bundle:nil];
                
                
                
            }
            
            
            
        }
        else{
            credits = [[CreditsViewController alloc] initWithNibName:@"CreditsViewController_iPad" bundle:nil];
            
        }
        [credits setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:credits animated:YES];
    }

}

@end
