#import <UIKit/UIKit.h>

@interface UITableView (TextFieldAdditions)

// query
-(NSIndexPath *) indexPathForFirstResponder;
-(UITextField *) currentFirstResponderTextField;

// change first responder
-(void) makeNextCellWithTextFieldFirstResponder;
-(void) makeFirstResponderForIndexPath: (NSIndexPath *) indexPath;
-(void) makeFirstResponderForIndexPath: (NSIndexPath *) indexPath scrollPosition: (UITableViewScrollPosition) scrollPosition;

// watch for keyboard presentation/dismissal [if you call beginXXX, you must call endXXX]
-(void) beginWatchingForKeyboardStateChanges;
-(void) endWatchingForKeyboardStateChanges;

@end
