//
//  ModalTVC.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 03/04/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ModalTVC.h"


@interface ModalTVC()

@property BOOL isGrid;

- (UIImage *) addBorderTo:(UIImage *)image;

- (void) toggleDoneButton;

@end


@implementation ModalTVC

@synthesize data = _data;
@synthesize selectedItems = _selectedItems;
@synthesize tableView = _tableView;
@synthesize delegate = _delegate;
@synthesize multipleChoice = _multipleChoice;
@synthesize modalTitle = _modalTitle;

-(NSMutableArray *) selectedItems
{
    if(!_selectedItems){
        _selectedItems = [[NSMutableArray alloc] init];
    }
    return _selectedItems;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.selectedItems.count == 0){
        self.doneButton.enabled = NO;
        self.doneButton.alpha = 0.6f;
    }
    
    //select grid (for images) or list (for text) as table view type depending on the data
    self.isGrid = NO;
    if([[self.data objectAtIndex:0] isKindOfClass:[UIImage class]])
        self.isGrid = YES;
    
    self.cancelButton.hidden = YES;
    if(self.isGrid){
        self.tableView.rowHeight = (0.225*self.view.frame.size.width*ceil((float)self.data.count/4) + 0.0375*self.view.frame.size.width);
        //TODO: hidden button made from the caller, more genearl approach
        self.cancelButton.hidden = NO;
    }
    
    
    //TODO: in grid mode, no distinction between multiplechoice.
}



#pragma mark
#pragma mark - TableView Delegate and Datasource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return  self.modalTitle;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section
{
    NSInteger ret = 0;
    
    //grid
    if (self.isGrid && (self.data.count>0))
        ret = 1;
    
    //list
    else ret = self.data.count;
    
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.isGrid){
        UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        for(int i = 0; i < self.data.count; i++) {
            @autoreleasepool {
                
                UIView *imview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width)];
                
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0.0375*self.view.frame.size.width,0.4125*self.view.frame.size.width, 0.4125*self.view.frame.size.width)];
                imageView.image = [self.data objectAtIndex:i];
                
                [imview addSubview:imageView];
                
                //unselected image
                UIGraphicsBeginImageContext(CGSizeMake(0.45*self.view.frame.size.width,0.45*self.view.frame.size.width));
                [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                //selected image
                UIGraphicsBeginImageContext(CGSizeMake(0.45*self.view.frame.size.width, 0.45*self.view.frame.size.width));
                imview.alpha = 0.65;
                [imview.layer  renderInContext:UIGraphicsGetCurrentContext()];
                UIImage *imageSelected = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.tag = i;
                
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
                    button.frame = CGRectMake(0.05*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.225*self.view.frame.size.width, 0.225*self.view.frame.size.width);
                
                else button.frame = CGRectMake(0.07*self.view.frame.size.width+0.225*self.view.frame.size.width*(i%4), 0.01875*self.view.frame.size.width+0.225*self.view.frame.size.width*(floor((i/4))), 0.2*self.view.frame.size.width, 0.2*self.view.frame.size.width);
                
                //if the cell is a selected item
                if ([self.selectedItems indexOfObject:[NSNumber numberWithInt:i]] == NSNotFound)
                    button.selected = NO;
                else button.selected = YES;
                
                [button addTarget:self
                           action:@selector(imageSelectedAction:)
                 forControlEvents:UIControlEventTouchUpInside];
                [button setImage:image forState:UIControlStateNormal];
                [button setImage:[self addBorderTo:imageSelected] forState:UIControlStateSelected];
                
                [cell addSubview:button];
            }
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
    
    //list
    else{
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        NSNumber *row = [NSNumber numberWithInt:indexPath.row];
        if([self.selectedItems indexOfObject:row] != NSNotFound) cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.textLabel.text = [self.data objectAtIndex:indexPath.row];
        
        return cell;
    }
        
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //list
    if(!self.isGrid){
        NSNumber *row = [NSNumber numberWithInt:indexPath.row];
        if([self.selectedItems indexOfObject:row] == NSNotFound){
            if(!self.multipleChoice) [self.selectedItems removeAllObjects];
            [self.selectedItems addObject:row];
        }
        else [self.selectedItems removeObject:row];
        
        //Enable done button when at list on item selected
        [self toggleDoneButton];
        
        [tableView reloadData];
    }
}

#pragma mark 
#pragma mark - IBActions

- (IBAction)doneAction:(id)sender
{    
    //send index of selected rows
    [self.delegate userSlection:[[NSArray alloc] initWithArray:self.selectedItems] for:self.modalTitle];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)imageSelectedAction:(UIButton *)button
{
    if(button.selected) [self.selectedItems removeObject:[NSNumber numberWithInt:button.tag]];
    else [self.selectedItems addObject:[NSNumber numberWithInt:button.tag]];
    
    button.selected = button.selected ? NO:YES;
    
    [self toggleDoneButton];
}

- (IBAction)cancelAction:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark
#pragma mark - Private methods

- (UIImage *) addBorderTo:(UIImage *)image
{
    CGImageRef bgimage = [image CGImage];
	float width = CGImageGetWidth(bgimage);
	float height = CGImageGetHeight(bgimage);
    // Create a temporary texture data buffer
	void *data = malloc(width * height * 4);
    
	// Draw image to buffer
	CGContextRef ctx = CGBitmapContextCreate(data,
                                             width,
                                             height,
                                             8,
                                             width * 4,
                                             CGImageGetColorSpace(image.CGImage),
                                             kCGImageAlphaPremultipliedLast);
	CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)width, (CGFloat)height), bgimage);
	//Set the stroke (pen) color
	CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:(160/255.0) green:(28.0/255.0) blue:(36.0/255.0) alpha:1.0].CGColor);
    
	//Set the width of the pen mark
	CGFloat borderWidth = (float)self.view.frame.size.width*0.4125*0.075;
	CGContextSetLineWidth(ctx, borderWidth);
    
	//Start at 0,0 and draw a square
    CGContextMoveToPoint(ctx, borderWidth/2, borderWidth/2);
	CGContextAddLineToPoint(ctx, self.view.frame.size.width*0.4125-borderWidth/2, borderWidth/2);
	CGContextAddLineToPoint(ctx, self.view.frame.size.width*0.4125-borderWidth/2, self.view.frame.size.width*0.4125-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2,self.view.frame.size.width*0.4125-borderWidth/2);
	CGContextAddLineToPoint(ctx, borderWidth/2, 0);
	//Draw it
	CGContextStrokePath(ctx);
    
    // write it to a new image
	CGImageRef cgimage = CGBitmapContextCreateImage(ctx);
	UIImage *newImage = [UIImage imageWithCGImage:cgimage];
	CFRelease(cgimage);
	CGContextRelease(ctx);
    free(data);
    
	return newImage;
}


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


- (void)viewDidUnload {
    [self setCancelButton:nil];
    [super viewDidUnload];
}
@end
