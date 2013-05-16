#import "EditableTableViewCell.h"

#define kLeading	10.0

@implementation EditableTableViewCell

@synthesize textField = _textField;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		_textField = [[UITextField alloc] initWithFrame: CGRectZero];
		_textField.minimumFontSize = 12;
		_textField.adjustsFontSizeToFitWidth = YES;
		[self addSubview: _textField];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) layoutSubviews
{
	[super layoutSubviews];
	
	CGRect contentRect = [[self contentView] bounds];
	CGSize textSize = [@"W" sizeWithFont: [[self textField] font]];
	self.textField.frame = CGRectIntegral( CGRectMake(contentRect.size.width / 2.0, (contentRect.size.height - textSize.height) / 2.0, (contentRect.size.width / 2.0) - (2.0 * kLeading), textSize.height) );
}

@end
