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

        [self setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"maskLayerSmall"]]];
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self addSubview:self.imageView];
        
        CGRect selectedImageFrame = CGRectMake(0, 0, self.bounds.size.width/3, self.bounds.size.width/3);
        selectedImageFrame.origin.y += (frame.size.height/2) - (selectedImageFrame.size.height/2);
        selectedImageFrame.origin.x += (frame.size.width/2) - (selectedImageFrame.size.width/2);
        
        self.selectedImageView = [[UIImageView alloc] initWithFrame:selectedImageFrame];
        [self.selectedImageView setImage:[UIImage imageNamed:@"checkmark"]];
        [self.selectedImageView.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.selectedImageView.layer setShadowOffset:CGSizeMake(1, 1)];
        [self.selectedImageView.layer setShadowOpacity:0.7];
        [self.selectedImageView.layer setShadowRadius:3];
        [self addSubview:self.selectedImageView];
        
        [self.selectedImageView setAlpha:0];
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
        [self.selectedImageView setTransform:CGAffineTransformIdentity];
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
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
