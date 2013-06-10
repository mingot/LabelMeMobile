//
//  ImageCell.m
//  LabelMe
//
//  Created by Josep Marc Mingot Hidalgo on 05/06/13.
//  Copyright (c) 2013 CSAIL. All rights reserved.
//

#import "ImageCell.h"

@implementation ImageCell

//@synthesize imageSelected = _imageSelected;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"ImageCell" owner:self options:nil];
        
        if ([arrayOfViews count] < 1) { return nil; }
        
        if (![[arrayOfViews objectAtIndex:0] isKindOfClass:[UICollectionViewCell class]]) { return nil; }
        
        self = [arrayOfViews objectAtIndex:0];
    }
    return self;
}

//- (BOOL) imageSelected
//{
//    return _imageSelected;
//}
//
//- (void) setImageSelected:(BOOL)imageSelected
//{
//    _imageSelected = imageSelected;
//    if (imageSelected) {
//        self.imageView.alpha = 0.5;
//    }else{
//        self.imageView.alpha = 1;
//        self.layer.borderColor = [UIColor redColor].CGColor;
//    }
//}

@end
