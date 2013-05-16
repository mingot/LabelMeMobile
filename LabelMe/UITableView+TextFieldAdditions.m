#import "UITableView+TextFieldAdditions.h"
#import "UIView+HierarchyAdditions.h"
#import <objc/runtime.h>

#define kNotificationObjectsKey		@"TextFieldAdditions_NotificationObservers"

@interface UITableView()
-(NSMutableArray *) notificationObservers;
-(UITextField *) textFieldForCell: (UITableViewCell *) cell;
-(BOOL) indexPath: (NSIndexPath *) indexPath isInRangeFromIndexPath: (NSIndexPath *) fromIndexPath  toIndexPath: (NSIndexPath *) toIndexPath;
-(BOOL) makeNextCellWithTextFieldFirstResponderFromIndexPath: (NSIndexPath *) fromIndexPath 
												 toIndexPath: (NSIndexPath *) toIndexPath;
@end

@implementation UITableView(TextFieldAdditions)


-(NSIndexPath *) indexPathForFirstResponder
{
	NSIndexPath *firstResponderIndexPath = nil;
	for( NSInteger section=0; section < [self numberOfSections]; section++ )
	{
		NSInteger rows = [[self dataSource] tableView: self numberOfRowsInSection: section];
		for( NSInteger row=0; row < rows; row++ )
		{
			UITableViewCell *cell = [self cellForRowAtIndexPath: [NSIndexPath indexPathForRow: row inSection: section]];
			UITextField *textField = [self textFieldForCell: cell];
			if( [textField isFirstResponder] )
			{
				firstResponderIndexPath = [NSIndexPath indexPathForRow: row inSection: section];
				break;
			}
		}
	}
	return firstResponderIndexPath;
}

-(UITextField *) currentFirstResponderTextField
{
	UITextField *textField = nil;
	NSIndexPath *currentFirstResponderIndexPath = [self indexPathForFirstResponder];	
	if( currentFirstResponderIndexPath )
	{
		UITableViewCell *cell = [self cellForRowAtIndexPath: currentFirstResponderIndexPath];
		textField = [self textFieldForCell: cell];
	}
	return textField;
}


-(void) makeNextCellWithTextFieldFirstResponder
{
	BOOL searchedAllCells = NO;
	NSIndexPath *fromIndexPath = [self indexPathForFirstResponder];
	if( !fromIndexPath )
	{
		fromIndexPath = [NSIndexPath indexPathForRow: 0 inSection:0];
		searchedAllCells = YES;
	}
	NSInteger lastSection = [self numberOfSections] - 1;
	NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow: [[self dataSource] tableView: self numberOfRowsInSection: lastSection] - 1 inSection: lastSection];
	
	// wrap around?
	if( ![self makeNextCellWithTextFieldFirstResponderFromIndexPath: fromIndexPath toIndexPath: toIndexPath] && !searchedAllCells )
	{
		[self makeNextCellWithTextFieldFirstResponderFromIndexPath: [NSIndexPath indexPathForRow: 0 inSection:0] toIndexPath: fromIndexPath];
	}
}

-(void) makeFirstResponderForIndexPath: (NSIndexPath *) indexPath
{
	[self makeFirstResponderForIndexPath: indexPath scrollPosition: UITableViewScrollPositionMiddle];
}

-(void) makeFirstResponderForIndexPath: (NSIndexPath *) indexPath scrollPosition: (UITableViewScrollPosition) scrollPosition
{
	UITableViewCell *cell = [self cellForRowAtIndexPath: indexPath];
	UITextField *textField = [self textFieldForCell: cell];
	[textField becomeFirstResponder];
	[self scrollToRowAtIndexPath: indexPath atScrollPosition: scrollPosition animated: YES];
}

-(void) beginWatchingForKeyboardStateChanges
{
	__weak UITableView *tableSelf = self;
	id observer = [[NSNotificationCenter defaultCenter] addObserverForName: UIKeyboardDidShowNotification
																	object: nil
																	 queue: nil
																usingBlock:^(NSNotification *notification) {
																	CGRect keyboardBounds = [[[notification userInfo] objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
																	CGRect translatedBounds = [self convertRect: keyboardBounds fromView: [[UIApplication sharedApplication] keyWindow]];
																	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, translatedBounds.size.height, 0);
																	
																	[tableSelf setContentInset: edgeInsets];
																	[tableSelf setScrollIndicatorInsets: edgeInsets];
																	
																	NSIndexPath *indexPath = [self indexPathForFirstResponder];
																	if( indexPath )
																	{
																		[self  scrollToRowAtIndexPath: indexPath atScrollPosition: UITableViewScrollPositionMiddle animated: YES];
																	}
																}];	
	[[self notificationObservers] addObject: observer];
	
	observer = [[NSNotificationCenter defaultCenter] addObserverForName: UIKeyboardDidHideNotification
																 object: nil
																  queue: nil
															 usingBlock:^(NSNotification *notification) {
																 [tableSelf setContentInset: UIEdgeInsetsZero];
																 [tableSelf setScrollIndicatorInsets: UIEdgeInsetsZero];
															 }];
	[[self notificationObservers] addObject: observer];
}

-(void) endWatchingForKeyboardStateChanges
{
	for( id observer in [self notificationObservers] )
	{
		[[NSNotificationCenter defaultCenter] removeObserver: observer];
	}
	[[self notificationObservers] removeAllObjects];
}



#pragma mark- Internal Methods

-(UITextField *) textFieldForCell: (UITableViewCell *) cell
{
	UITextField *textField = nil;
	for( UIView *subview in [cell allSubviews] )
	{
		if( [subview isKindOfClass: [UITextField class]] )
		{
			UITextField *textFieldToCheck = (UITextField *)subview;
			if( [textFieldToCheck isEnabled] )
			{
				textField = (UITextField *)subview;
				break;
			}
		}
	}
	return textField;
}

-(BOOL) indexPath: (NSIndexPath *) indexPath isInRangeFromIndexPath: (NSIndexPath *) fromIndexPath  toIndexPath: (NSIndexPath *) toIndexPath
{
	BOOL isInRange = NO;
	if( [indexPath section] >= [fromIndexPath section] && [indexPath section] <= [toIndexPath section] )
	{
		// assume we passed; the only way it can fail is on the edges.
		isInRange = YES;
		
		if( [indexPath section] == [fromIndexPath section] && isInRange )
			isInRange = [indexPath row] >= [fromIndexPath row];
		
		if( [indexPath section] == [toIndexPath section] && isInRange )
			isInRange = [indexPath row] <= [toIndexPath row];	
		
	}
	return isInRange;
}

-(BOOL) makeNextCellWithTextFieldFirstResponderFromIndexPath: (NSIndexPath *) fromIndexPath 
												 toIndexPath: (NSIndexPath *) toIndexPath
{
	BOOL found = NO;
	NSIndexPath *currentFirstResponderIndexPath = [self indexPathForFirstResponder];
	NSIndexPath *newIndexPath = nil;
	
	for( NSInteger section=[fromIndexPath section]; section<=[toIndexPath section] && !found; section++ )
	{
		NSInteger rows = [[self dataSource] tableView: self numberOfRowsInSection: section];
		NSInteger startRow = 0;
		if( section == [fromIndexPath section] )
			startRow = [fromIndexPath row];
		NSInteger endRow = rows - 1;
		if( section == [toIndexPath section] )
			endRow = [toIndexPath row];
		
		BOOL deferredFirstResponder = NO;
		for( NSInteger row=startRow; row<=endRow && !found; row++ )
		{
			NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow: row inSection: section];
			if( !([currentFirstResponderIndexPath section] == section && [currentFirstResponderIndexPath row] == row) )
			{
				UITableViewCell *cell = nil;
				if( [[self indexPathsForVisibleRows] containsObject: currentIndexPath] )
				{
					cell = [self cellForRowAtIndexPath: [NSIndexPath indexPathForRow: row inSection: section]];
				}
				else
				{
					cell = [[self dataSource] tableView: self cellForRowAtIndexPath: currentIndexPath];
					deferredFirstResponder = YES;
					
				}
				if( deferredFirstResponder )
				{	
					[self performSelector: @selector(makeFirstResponderForIndexPath:)  withObject: currentIndexPath afterDelay: 0.4];		// unicorns weep.  sorry.
				}
				else
				{
					[self makeFirstResponderForIndexPath: currentIndexPath];
				}
				if( [self textFieldForCell: cell] )
				{
					newIndexPath = currentIndexPath;
					found = YES;
				}
			}
		}
	}
	
	if( newIndexPath )
	{
		[self scrollToRowAtIndexPath: newIndexPath atScrollPosition: UITableViewScrollPositionMiddle animated: YES];
	}
	
	return found;
}


-(NSMutableArray *) notificationObservers
{
	NSMutableArray *notificationObservers = objc_getAssociatedObject( self, kNotificationObjectsKey );
	if( !notificationObservers )
	{
		notificationObservers = [NSMutableArray new];
		objc_setAssociatedObject( self, kNotificationObjectsKey, notificationObservers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return notificationObservers;
}

@end


