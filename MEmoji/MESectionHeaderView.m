//
//  MESectionHeaderReusableView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MESectionHeaderView.h"
#import "MECaptureButton.h"

const static CGFloat arrowButtonWidth = 37;

@implementation MESectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id<MESectionHeaderViewDelegate >)delegate;
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.delegate = delegate;
        
        [self setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.85]];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 5)];
        [self.layer setShadowOpacity:0.2];
        [self.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.bounds].CGPath];
        [self.layer setShadowRadius:7];

        // Left Button
        self.leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftButton setFrame:CGRectMake(0,
                                             0,
                                             arrowButtonWidth,
                                             frame.size.height)];
        [self.leftButton setShowsTouchWhenHighlighted:YES];
        [self.leftButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.leftButton setTag:MEHeaderButtonTypeLeftArrow];
        [self.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
        [self.leftButton setAlpha:0.5];
        [self.leftButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.leftButton];
        
        
        // Title Label
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(arrowButtonWidth,
                                                                    0,
                                                                    (frame.size.width/2) - arrowButtonWidth - (captureButtonDiameter/2),
                                                                    frame.size.height)];
        [self.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [self.titleLabel setFont:[MEModel mainFontWithSize:15]];
        [self.titleLabel setNumberOfLines:1];
        [self.titleLabel setTextColor:[UIColor whiteColor]];
        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:self.titleLabel];
        
        
        // Right Button
        self.rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightButton setFrame:CGRectMake(frame.size.width - arrowButtonWidth,
                                              0,
                                              arrowButtonWidth,
                                              frame.size.height)];
        [self.rightButton setShowsTouchWhenHighlighted:YES];
        [self.rightButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.rightButton setTag:MEHeaderButtonTypeRightArrow];
        [self.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
        [self.rightButton setAlpha:0.5];
        [self.rightButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.rightButton];
        
        
        // Purchase Button
        self.purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.purchaseButton setFrame:CGRectMake((frame.size.width/2) + (captureButtonDiameter/2),
                                                 0,
                                                 frame.size.width/2 - self.rightButton.bounds.size.width - (captureButtonDiameter/2),
                                                 frame.size.height)];
        [self.purchaseButton.titleLabel setFont:[MEModel mainFontWithSize:15]];
        [self.purchaseButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [self.purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.purchaseButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [self.purchaseButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.purchaseButton];
    }
    return self;
}

- (void)handleTap:(UIButton *)sender
{
    [self.delegate sectionHeader:self tappedButton:sender];
}
@end
