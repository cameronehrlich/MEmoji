//
//  MEProgressView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 10/2/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEProgressView.h"

@implementation MEProgressView

- (instancetype)initWithFrame:(CGRect)frame andColor:(UIColor *)color
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.colorView = [[UIView alloc] initWithFrame:self.bounds];
        [self.colorView setBackgroundColor:color];
        [self.colorView setAlpha:0];
        [self addSubview:self.colorView];
        [self setClipsToBounds:YES];
        
        self.color = color;
        self.duration = 5; // default
    }
    return self;
}

- (void)startAnimationWithCompletion:(ProgressCompletion)completionBlock;
{
    CGRect startingFrame = CGRectMake(-self.bounds.size.width, 0, self.bounds.size.width, self.bounds.size.height);
    CGRect endingFrame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self.colorView setFrame:startingFrame];
    [self.colorView setAlpha:1];
    [self setBackgroundColor:[self.color colorWithAlphaComponent:0.2]];
    
    [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
        [self.colorView setFrame:endingFrame];
    } completion:^(BOOL finished) {
        if (finished) {
            completionBlock();
        }
    }];
}

- (void)reset
{
    [self setBackgroundColor:[UIColor clearColor]];
    [self.colorView setAlpha:0];
}

@end
