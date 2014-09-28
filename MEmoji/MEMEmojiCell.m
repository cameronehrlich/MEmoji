//
//  MEMEmojiCell.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEMEmojiCell.h"

@implementation MEMEmojiCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setBackgroundColor:[[UIColor grayColor] colorWithAlphaComponent:0.5]];
        
        self.imageView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        [self.imageView setAnimatesWhileScrolling:YES];
        [self addSubview:self.imageView];
        
        CGRect deleteViewFrame = CGRectMake(0, 0, self.bounds.size.width/2, self.bounds.size.width/2);
        deleteViewFrame.origin.x = self.bounds.size.width/2 - (deleteViewFrame.size.width/2);
        deleteViewFrame.origin.y = self.bounds.size.height/2 - (deleteViewFrame.size.height/2);
        self.deleteImageView = [[UIImageView alloc] initWithFrame:deleteViewFrame];
        [self.deleteImageView setImage:[UIImage imageNamed:@"deleteX"]];
        [self.deleteImageView setAlpha:0];
        [self addSubview:self.deleteImageView];
    }
    return self;
}

- (void)setEditMode:(BOOL)editMode
{
    _editMode = editMode;
    
    if (editMode) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
            [self.deleteImageView setAlpha:1];
            [self.deleteImageView setTransform:CGAffineTransformRotate(self.deleteImageView.transform, M_PI_2)];
        }completion:^(BOOL finished) {
            
         }];
    }else{
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
            [self.deleteImageView setTransform:CGAffineTransformIdentity];
        }completion:^(BOOL finished) {
            [self.deleteImageView setAlpha:0];
        }];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
        
        if (highlighted) {
            if (self.editMode) {
                [self.deleteImageView setTransform:CGAffineTransformScale(self.deleteImageView.transform, -0.5, -0.5)];
            }
        }else{
            [self.deleteImageView setTransform:CGAffineTransformIdentity];
        }
    } completion:^(BOOL finished) {
        //
    }];
}

@end
