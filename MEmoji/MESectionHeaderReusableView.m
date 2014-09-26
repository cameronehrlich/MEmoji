//
//  MESectionHeaderReusableView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MESectionHeaderReusableView.h"
#import "MECaptureButton.h"

@implementation MESectionHeaderReusableView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Left
        self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftButton setFrame:CGRectMake(0,
                                             0,
                                             frame.size.height,
                                             self.frame.size.height)];
        [self.leftButton setShowsTouchWhenHighlighted:YES];
        [self.leftButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.leftButton setTransform:CGAffineTransformMakeScale(0.55, 0.55)];
        [self.leftButton setAlpha:0.4];
        [self addSubview:self.leftButton];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.height,
                                                                    0,
                                                                    (frame.size.width/2) - self.leftButton.bounds.size.width - (captureButtonDiameter/2),
                                                                    frame.size.height)];
        [self.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [self.titleLabel setFont:[MEModel mainFontWithSize:13]];
        [self.titleLabel setNumberOfLines:2];
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
        [self.rightButton setTransform:CGAffineTransformMakeScale(0.55, 0.55)];
        [self.rightButton setAlpha:0.4];
        [self addSubview:self.rightButton];
        
        self.purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.purchaseButton setFrame:CGRectMake((frame.size.width/2) + (captureButtonDiameter/2),
                                                 0,
                                                 frame.size.width/2 - self.rightButton.bounds.size.width - (captureButtonDiameter/2),
                                                 frame.size.height)];
        [self.purchaseButton.titleLabel setFont:[MEModel mainFontWithSize:13]];
        [self.purchaseButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [self addSubview:self.purchaseButton];
    }
    return self;
}

@end
