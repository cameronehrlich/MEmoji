//
//  MESectionHeaderReusableView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MESectionHeaderView.h"
#import "MECaptureButton.h"

@implementation MESectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.85]];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 5)];
        [self.layer setShadowOpacity:0.2];
        [self.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.bounds].CGPath];
        [self.layer setShadowRadius:7];

        // Left
        self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftButton setFrame:CGRectMake(0,
                                             0,
                                             frame.size.height,
                                             self.frame.size.height)];
        [self.leftButton setShowsTouchWhenHighlighted:YES];
        [self.leftButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.leftButton setTransform:CGAffineTransformMakeScale(0.6, 0.6)];
        [self.leftButton setAlpha:0.4];
        [self addSubview:self.leftButton];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.height,
                                                                    0,
                                                                    (frame.size.width/2) - self.leftButton.bounds.size.width - (captureButtonDiameter/2),
                                                                    frame.size.height)];
        [self.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [self.titleLabel setFont:[MEModel mainFontWithSize:20]];
        [self.titleLabel setNumberOfLines:1];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:self.titleLabel];
        
        
        // Right
        self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightButton setFrame:CGRectMake(frame.size.width - frame.size.height,
                                              0,
                                              frame.size.height,
                                              frame.size.height)];
        [self.rightButton setShowsTouchWhenHighlighted:YES];
        [self.rightButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.rightButton setTransform:CGAffineTransformMakeScale(0.6, 0.6)];
        [self.rightButton setAlpha:0.4];
        [self addSubview:self.rightButton];
        
        self.purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.purchaseButton setFrame:CGRectMake((frame.size.width/2) + (captureButtonDiameter/2),
                                                 0,
                                                 frame.size.width/2 - self.rightButton.bounds.size.width - (captureButtonDiameter/2),
                                                 frame.size.height)];
        [self.purchaseButton.titleLabel setFont:[MEModel mainFontWithSize:20]];
        [self.purchaseButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [self.purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.purchaseButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [self addSubview:self.purchaseButton];
    }
    return self;
}

@end
