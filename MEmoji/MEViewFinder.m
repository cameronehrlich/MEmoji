//
//  MEViewFinder.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/26/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewFinder.h"
#import <UIView+Positioning.h>

@implementation MEViewFinder

- (instancetype)initWithFrame:(CGRect)frame previewLayer:(CALayer *)previewLayer
{
    self = [super initWithFrame:frame];
    if (self) {
        self.previewLayer = previewLayer;
        [self.previewLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self.layer addSublayer:self.previewLayer];
        
        self.maskLayer = [CALayer layer];
        [self.maskLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self.maskLayer setContents:(id)[UIImage imageNamed:@"maskLayer"].CGImage];
        [self.layer insertSublayer:self.maskLayer above:self.previewLayer];
        [self setShowingMask:NO];
        
        CGRect cornerbuttonRect = CGRectMake(0, 0, 30, 30);
        
        self.topLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.topLeftButton setFrame:cornerbuttonRect];
        
        self.topRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.topRightButton setFrame:cornerbuttonRect];
        [self.topRightButton setRight:self.right];
        
        self.bottomLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bottomLeftButton setFrame:cornerbuttonRect];
        [self.bottomLeftButton setBottom:self.bottom];
        
        self.bottomRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bottomRightButton setFrame:cornerbuttonRect];
        [self.bottomRightButton setRight:self.right];
        [self.bottomRightButton setBottom:self.bottom];
        
        _allButtons = @[self.topLeftButton, self.topRightButton, self.bottomLeftButton, self.bottomRightButton];
        
        for (UIButton *button in self.allButtons) {
            [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
            [button.imageView.layer setShadowColor:[UIColor blackColor].CGColor];
            [button.imageView.layer setShadowOffset:CGSizeMake(0, 0)];
            [button.imageView.layer setShadowOpacity:0.5];
            [button.imageView.layer setShadowRadius:1];
            [button setShowsTouchWhenHighlighted:YES];
            [button addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
        }
        
        // Reposition buttons
        CGFloat margin = 10;
        self.topLeftButton.y += margin;
        self.topLeftButton.x += margin;
        
        self.topRightButton.y += margin;
        self.topRightButton.x -= margin;

        self.bottomLeftButton.y -= margin;
        self.bottomLeftButton.x += margin;
        
        self.bottomRightButton.y -= margin;
        self.bottomRightButton.x -= margin;
        
    }
    return self;
}

- (void)handleTap:(UIButton *)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.delegate viewFinder:self didTapButton:sender];
    });
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [sender setTransform:CGAffineTransformMakeScale(1.3, 1.3)];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [sender setTransform:CGAffineTransformIdentity];
        } completion:nil];
    }];
}


- (void)setShowingMask:(BOOL)showingMask
{
    _showingMask = showingMask;
    if (showingMask) {
        [self.maskLayer setOpacity:0.7];
    }else{
        [self.maskLayer setOpacity:0];
    }
}

@end
