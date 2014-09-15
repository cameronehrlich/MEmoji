//
//  MEOverlayCellCollectionViewCell.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/15/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEOverlayCell.h"

@implementation MEOverlayCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self.backgroundView.layer setContents:(id)[UIImage imageNamed:@"maskLayer"]];
        self.maskingView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.maskingView setImage:[UIImage imageNamed:@"maskLayer"]];
        [self.maskingView setAlpha:0.5];
        [self.layer setCornerRadius:15];
        [self addSubview:self.maskingView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self addSubview:self.imageView];
        
        self.selectedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [self.selectedImageView setImage:[UIImage imageNamed:@"checkmark"]];
        [self.selectedImageView setHidden:YES];
        [self addSubview:self.selectedImageView];
        
    }
    return self;
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self.selectedImageView setHidden:!selected];
}
@end
