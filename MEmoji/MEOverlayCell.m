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

        self.maskingView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.maskingView setImage:[UIImage imageNamed:@"maskLayerSmall"]];
        [self.maskingView setAlpha:0.9];
        [self addSubview:self.maskingView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self addSubview:self.imageView];
        
        CGRect selectedImageFrame = CGRectMake(0, 0, 45, 45);
        selectedImageFrame.origin.y += (frame.size.height/2) - (selectedImageFrame.size.height/2);
        selectedImageFrame.origin.x += (frame.size.width/2) - (selectedImageFrame.size.width/2);
        
        self.selectedImageView = [[UIImageView alloc] initWithFrame:selectedImageFrame];
        [self.selectedImageView setImage:[UIImage imageNamed:@"checkmark"]];
        [self.selectedImageView.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.selectedImageView.layer setShadowOffset:CGSizeMake(1, 1)];
        [self.selectedImageView.layer setShadowOpacity:0.7];
        [self.selectedImageView.layer setShadowRadius:3];
        [self addSubview:self.selectedImageView];

        [self setSelected:NO];
    }
    return self;
}


- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) {
        [self.selectedImageView setTransform:CGAffineTransformIdentity];
        [self.selectedImageView setAlpha:1];
    }else{
        [self.selectedImageView setAlpha:1];
        [self.selectedImageView setTransform:CGAffineTransformIdentity];
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.selectedImageView setAlpha:0];
            [self.selectedImageView setTransform:CGAffineTransformMakeScale(2, 2)];
        } completion:nil];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted) {
        [self setAlpha:0.5];
    }else{
        [self setAlpha:1];
    }
}

@end
