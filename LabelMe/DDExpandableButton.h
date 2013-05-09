//
//  DDExpandableButton.h
//  https://github.com/ddebin/DDExpandableButton
//

#ifndef __IPHONE_3_0
#warning "This project uses features only available in iOS SDK 3.0 and later."
#endif

#import <UIKit/UIKit.h>


#define DDView UIView <DDExpandableButtonViewSource>

@protocol DDExpandableButtonViewSource;

@interface DDExpandableButton : UIControl
{
	BOOL		expanded;
	BOOL		useAnimation;
	BOOL		toggleMode;
	CGFloat		timeout;
	CGFloat 	horizontalPadding;
	CGFloat 	verticalPadding;
	CGFloat 	borderWidth;
	CGFloat 	innerBorderWidth;
    NSUInteger	selectedItem;
	UIColor		*borderColor;
	UIColor 	*textColor;
	UIFont  	*labelFont;
	UIFont  	*unSelectedLabelFont;
	
	CGFloat		cornerAdditionalPadding;
	CGFloat 	leftWidth;
	CGFloat 	maxHeight;
	CGFloat 	maxWidth;
    NSArray 	*labels;
	DDView		*leftTitleView;
}

// Current button status (if expanded or shrunk).
@property 	BOOL		expanded;

// Use animation during button state stransitions.
@property 	BOOL		useAnimation;

// Use button as a toggle (like "HDR On"/"HDR Off" button in camera app).
@property 	BOOL		toggleMode;

// To shrink the button after a timeout. Use `0` if you want to disable timeout.
@property 	CGFloat		timeout;

// Horizontal padding space between items.
@property 	CGFloat 	horizontalPadding;

// Vertical padding space above and below items.
@property 	CGFloat 	verticalPadding;

// Width (thickness) of the button border.
@property 	CGFloat 	borderWidth;

// Width (thickness) of the inner borders between items.
@property 	CGFloat 	innerBorderWidth;

// Selected item number.
@property 	NSUInteger	selectedItem;

// Color of the button and inner borders.
@property (nonatomic,strong)	UIColor		*borderColor;

// Color of text labels.
@property (nonatomic,strong)	UIColor		*textColor;

// Font of text labels.
@property (nonatomic,strong)	UIFont		*labelFont;

// Font of unselected text labels. Nil if not different from labelFont.
@property (nonatomic,strong)	UIFont		*unSelectedLabelFont;

// Access UIView used to draw labels.
@property (nonatomic,readonly)	NSArray 	*labels;

- (id)initWithPoint:(CGPoint)point leftTitle:(id)leftTitle buttons:(NSArray *)buttons;

- (void)setSelectedItem:(NSUInteger)selected animated:(BOOL)animated;
- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated;
- (void)setLeftTitle:(id)leftTitle;
- (void)setButtons:(NSArray *)buttons;

- (void)disableTimeout;
- (void)updateDisplay;

@end

@protocol DDExpandableButtonViewSource <NSObject>

- (CGSize)defaultFrameSize;

@optional
- (void)setHighlighted:(BOOL)highlighted;

@end