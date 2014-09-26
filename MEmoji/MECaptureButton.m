//
//  MECaptureButton.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MECaptureButton.h"

@implementation MECaptureButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.rangeOfMotion = 10;
        self.scaleTransform = CGAffineTransformMakeScale(1.3, 1.3);
        
        self.backgroundLayer = [CALayer layer];
        [self.backgroundLayer setFrame:self.bounds];
        [self.backgroundLayer setCornerRadius:frame.size.width/2];
        [self.backgroundLayer setContents:(id)[UIImage imageNamed:@"captureButtonRed"].CGImage];
        [self.backgroundLayer setMasksToBounds:YES];
        [self.layer addSublayer:self.backgroundLayer];
        [self.layer setCornerRadius:self.bounds.size.width/2];
        [self.layer setShadowColor:[UIColor grayColor].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 5)];
        [self.layer setShadowOpacity:0.5];
        [self.layer setShadowRadius:3.7];
        [self.layer setShadowPath:[UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath];
        UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        [effectX setMinimumRelativeValue:@(-1 * self.rangeOfMotion)];
        [effectX setMaximumRelativeValue:@(self.rangeOfMotion)];
        [effectY setMinimumRelativeValue:@(-1 * self.rangeOfMotion)];
        [effectY setMaximumRelativeValue:@(self.rangeOfMotion)];
        [self addMotionEffect:effectX];
        [self addMotionEffect:effectY];
        
        self.spinnerView = [[LLARingSpinnerView alloc] initWithFrame:self.bounds];
        [self.spinnerView setLineWidth:3];
        [self.spinnerView setAlpha:0];
        [self addSubview:self.spinnerView];
    }
    return self;
}

- (void)startSpinning
{
    [UIView animateWithDuration:0.5 animations:^{
        [self.spinnerView startAnimating];
        [self.spinnerView setAlpha:1];
    }];
}

- (void)stopSpinning
{
    [UIView animateWithDuration:0.5 animations:^{
        [self.spinnerView setAlpha:0];
    } completion:^(BOOL finished) {
        [self.spinnerView stopAnimating];
    }];
}

- (void)scaleUp
{
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self setTransform:self.scaleTransform];
    } completion:nil];
}

- (void)scaleDown
{
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self setTransform:CGAffineTransformIdentity];
    } completion:nil];
}


@end
