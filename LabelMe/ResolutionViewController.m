//
//  ResolutionViewController.m
//  LabelMe
//
//  Created by Dolores on 17/10/12.
//  Copyright (c) 2012 CSAIL. All rights reserved.
//

#import "ResolutionViewController.h"

@interface ResolutionViewController ()

@end

@implementation ResolutionViewController
@synthesize tableView = _tableView;
@synthesize username = _username;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.username = [[NSString alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.tableView setBackgroundView:nil];

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    //self.tableView.backgroundColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1.0];
    self.view.backgroundColor = [UIColor colorWithRed:(200/255.0) green:(200/255.0) blue:(200/255.0) alpha:1.0];
    //self.view.backgroundColor = [UIColor colorWithRed:(236/255.0) green:(32/255.0) blue:(28/255.0) alpha:1.0];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];

    self.tableView.backgroundColor = [UIColor clearColor];
    [self.tableView setBackgroundView:nil];
    [self setTitle:@"Image Resolution"];
    [self.view addSubview:self.tableView];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
       return 9;
}





- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
     static NSString *CellIdentifier = @"Cell";
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
     //
     if (cell == nil) {
     cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
     }
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // change to accomodate user
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,self.username ];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *dictnum = [dict objectForKey:@"resolution"];
    switch (indexPath.row) {
        case 0:
            [cell.textLabel setText:@"Max"];
            cell.tag = 0;
            break;
        
        case 1:
            [cell.textLabel setText:@"2220 X 2960"];
            cell.tag = 2960;
            break;
        case 2:
            [cell.textLabel setText:@"1920 X 2560"];
            cell.tag = 2560;
            break;
        case 3:
            [cell.textLabel setText:@"1620 X 2160"];
            cell.tag = 2160;
            break;
        case 4:
            [cell.textLabel setText:@"1440 X 1920"];
            cell.tag = 1920;
            break;
        case 5:
            [cell.textLabel setText:@"1230 X 1640"];
            cell.tag = 1640;
            break;
        case 6:
            [cell.textLabel setText:@"960 X 1280"];
            cell.tag = 1280;
            break;
        case 7:
            [cell.textLabel setText:@"630 X 840"];
            cell.tag = 840;
            break;
        case 8:
            [cell.textLabel setText:@"480 X 640"];
            cell.tag = 640;
            break;
            
        default:
            break;
    }
    
    if (cell.tag == dictnum.intValue) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else{
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    return cell;
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    // change to accomodate user
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@",documentsDirectory,self.username ];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:@"settings.plist"]];
    NSNumber *dictnum = [NSNumber numberWithInteger:[tableView cellForRowAtIndexPath:indexPath].tag];
    [dict removeObjectForKey:@"resolution"];
    [dict setObject:dictnum forKey:@"resolution"];
    [dict writeToFile:[path stringByAppendingPathComponent:@"settings.plist"] atomically:YES];
    [self.tableView reloadData];
    
}
@end
