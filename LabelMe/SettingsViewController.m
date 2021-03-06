//
//  SettingsViewController.m
//  LabelMe
//
//  Created by Dolores on 29/09/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SettingsViewController.h"
#import "Constants.h"
#import "ResolutionViewController.h"
#import "ServerConnection.h"
#import "CreditsViewController.h"
#import "NSObject+Folders.h"
#import "UIImage+Resize.h"
#import "LMUINavigationController.h"



@implementation SettingsViewController


#pragma mark
#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:nil tag:3];
        [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"settingsActive.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"settingsDisabled.png"]];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            self.website = [[WebsiteViewController alloc] initWithNibName:@"WebsiteViewController_iPhone" bundle:nil];
        else self.website = [[WebsiteViewController alloc] initWithNibName:@"WebsiteViewController_iPhone" bundle:nil];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBackgroundImage:[LMUINavigationController drawImageWithSolidColor:[UIColor redColor]] forBarMetrics:UIBarMetricsDefault];

    UIBarButtonItem *logOutButton = [[UIBarButtonItem alloc] initWithTitle:@"Log out" style:UIBarButtonItemStylePlain target:self action:@selector(logOutAction:)];
    
    self.navigationItem.rightBarButtonItem = logOutButton;
    
    //titleView: LabelMe Logo and title images
    UIImage *titleImage = [UIImage imageNamed:@"settingsTitle.png"];
    UIImageView *titleView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height)/2, 0, titleImage.size.width*self.navigationController.navigationBar.frame.size.height/titleImage.size.height, self.navigationController.navigationBar.frame.size.height)];
    titleView.image = titleImage;
    [self.navigationItem setTitleView:titleView];

    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:nil];

    [self setTitle:@"Settings"];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - IBActions

-(IBAction)logOutAction:(id)sender
{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    [filemng removeItemAtPath:[[documentsDirectory stringByAppendingPathComponent:@"RememberMe"] stringByAppendingPathComponent:@"password.txt"] error:NULL];
    
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
        
    }else { // No camera, just use the library.
        UIActionSheet *photoSourceSheet = [[UIActionSheet
                                            alloc] initWithTitle:@"" delegate:self
                                           cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete Photo"
                                           otherButtonTitles: @"Choose Existing Photo",  nil];
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
    
    [dict writeToFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"] atomically:NO];
}

-(IBAction)stepperDidChange:(id)sender
{
    NSArray *paths = [self newArrayWithFolders:self.username];
    UIStepper *stepper = (UIStepper *) sender;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
    
    [dict setObject:[NSNumber numberWithDouble:stepper.value] forKey:@"hogdimension"];

    [self.tableView reloadData];
    
    [dict writeToFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"] atomically:NO];
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
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.delegate = self;
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
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            if ([self.popover isPopoverVisible]) {
                [self.popover dismissPopoverAnimated:YES];
                
            }else{
                UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:picker];
                [popover presentPopoverFromRect:actionSheet.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                self.popover = popover;
            }

        }else [self presentViewController:picker animated:YES completion:NULL];
        
    }else [self presentViewController:picker animated:YES completion:NULL];

}



#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSFileManager * filemng = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString:[[documentsDirectory stringByAppendingPathComponent:self.username] stringByAppendingPathComponent:@"profilepicture.jpg" ]];
    UIImage *img = (UIImage * )[info objectForKey:UIImagePickerControllerOriginalImage];
    if ([filemng createFileAtPath:path contents:UIImageJPEGRepresentation([img thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh], 1.0) attributes:nil]) {
        ServerConnection *sConnection = [[ServerConnection alloc]init];
        [sConnection uploadProfilePicture:[img thumbnailImage:300 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh]];
    }
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);

    [self.tableView reloadData];
    [picker dismissViewControllerAnimated:NO completion:NULL];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark TableView Delegate&Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
    NSString * ret = [[NSString alloc] init];
    if (section == 3)
        ret = @"Advanced settings";
    if(section == 4)
        ret = @"Detector settings";
    
    return  ret;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) return  self.view.frame.size.width/2;
    else return tableView.rowHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    if (sectionTitle == nil)
        return nil;
    
    // Create label with section title
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 6, 300, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0];
    label.text = sectionTitle;
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [view addSubview:label];
    
    return view;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSFileManager *filemng = [NSFileManager defaultManager];
    NSArray *paths = [self newArrayWithFolders:self.username];
    UITableViewCell *cell = nil;

    //Profile picture
    if (indexPath.section == 0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIButton *profilePictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cell.imageView setBackgroundColor:[UIColor clearColor]];
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 10.0;
        if (![filemng fileExistsAtPath:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]])
            [cell.imageView setImage:[UIImage imageNamed:@"silueta.png"]];
            
        else [cell.imageView  setImage:[UIImage imageWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"profilepicture.jpg"]] ];

        
        [profilePictureButton setFrame:CGRectMake(0.0625*self.view.frame.size.width, 0.03125*self.view.frame.size.width, self.view.frame.size.width/2,  self.view.frame.size.width/2)];
        [profilePictureButton addTarget:self action:@selector(profilePictureAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:profilePictureButton];
        [cell.textLabel setText:self.username];

    //number of images
    }else if (indexPath.section == 1){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        NSNumber *numberfiles =[NSNumber numberWithInteger: [[filemng contentsOfDirectoryAtPath:[paths objectAtIndex:THUMB] error:NULL] count]];
        
        [cell.textLabel setText:@"Number of images: "];
        [cell.detailTextLabel setText:numberfiles.stringValue];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:160/255.0f green:32/255.0f blue:28/255.0f alpha:1.0]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    
    //go to labelme website
    }else if (indexPath.section == 2){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
        [cell.textLabel setText:@"Go to LabelMe Website"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    
    //advanced settings
    }else if (indexPath.section == 3){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
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
    
    //detector settings
    }else if(indexPath.section == 4){
        
        NSDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[[paths objectAtIndex:USER] stringByAppendingPathComponent:@"settings.plist"]];
        UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
        stepper.value = [(NSNumber *)[dict objectForKey:@"hogdimension"] doubleValue];
        stepper.maximumValue = 14;
        stepper.minimumValue = 4;
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.textLabel.text = [NSString stringWithFormat: @"Max HOG: %d", (int) stepper.value];
        cell.accessoryView = stepper;
        [stepper addTarget:self action:@selector(stepperDidChange:) forControlEvents:UIControlEventValueChanged];
        
    //about
    }else if (indexPath.section == 5){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
        [cell.textLabel setText:@"About LabelMe"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    }

    

    
    
    return cell;

}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //website
    if (indexPath.section == 2) {
        [self.website setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:self.website animated:YES];
    
    //image resolution election
    }else if ((indexPath.section == 3) && (indexPath.row == 1)) {
        
        ResolutionViewController *resolutionVC = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            resolutionVC = [[ResolutionViewController alloc] initWithNibName:@"ResolutionViewController_iPhone" bundle:nil];
        else resolutionVC = [[ResolutionViewController alloc] initWithNibName:@"ResolutionViewController_iPhone" bundle:nil];


        resolutionVC.username = self.username;
        [self.navigationController pushViewController:resolutionVC animated:YES];
    
    
    }else if ((indexPath.section == 5) ) {
        CreditsViewController *creditsVC = creditsVC = [[CreditsViewController alloc] initWithNibName:@"CreditsViewController" bundle:nil];
        [creditsVC setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:creditsVC animated:YES];
    }

}

@end
