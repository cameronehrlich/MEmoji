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
        
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:self.bounds];
        [loadingLabel setFont:[MEModel mainFontWithSize:9]];
        [loadingLabel setAdjustsFontSizeToFitWidth:YES];
        [loadingLabel setTextAlignment:NSTextAlignmentCenter];
        [loadingLabel setText:@"Loading..."];
        [loadingLabel setTextColor:[UIColor lightTextColor]];
        [self addSubview:loadingLabel];
        
        _imageView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        [self addSubview:_imageView];
        
        CGRect deleteViewFrame = CGRectMake(0, 0, self.bounds.size.width/1.5, self.bounds.size.width/1.5);
        deleteViewFrame.origin.x = self.bounds.size.width/2 - (deleteViewFrame.size.width/2);
        deleteViewFrame.origin.y = self.bounds.size.height/2 - (deleteViewFrame.size.height/2);
        
        _deleteImageView = [[UIImageView alloc] initWithFrame:deleteViewFrame];
        [_deleteImageView setImage:[UIImage imageNamed:@"deleteX"]];
        [_deleteImageView setAlpha:0];
        [_deleteImageView.layer setShadowColor:[UIColor blackColor].CGColor];
        [_deleteImageView.layer setShadowOpacity:0.7];
        [_deleteImageView.layer setShadowRadius:2];
        [self addSubview:_deleteImageView];
    }
    return self;
}

- (void)setEditMode:(BOOL)editMode
{
    _editMode = editMode;
    
    if (editMode) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
            [self.deleteImageView setAlpha:0.7];
            [self.deleteImageView setTransform:CGAffineTransformRotate(self.deleteImageView.transform, M_PI_2)];
        }completion:^(BOOL finished) {
            
         }];
    }else{
        [UIView animateWithDuration:0.5 animations:^{
            [self.deleteImageView setTransform:CGAffineTransformIdentity];
            [self.deleteImageView setAlpha:0];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        [self setAlpha:0.7];
    }else{
        [self setAlpha:1];
    }
    
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut) animations:^{
        
        if (highlighted) {
            if (self.editMode) {
                [self.deleteImageView setTransform:CGAffineTransformScale(self.deleteImageView.transform, -0.5, -0.5)];
            }
        }else{
            [self.deleteImageView setTransform:CGAffineTransformIdentity];
        }
    } completion:nil];
}

@end
