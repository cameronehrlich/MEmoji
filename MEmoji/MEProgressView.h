//
//  MEProgressView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 10/2/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

typedef void (^ProgressCompletion)();

@interface MEProgressView : UIView

@property (nonatomic, strong) UIView *colorView;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) BOOL isAnimating;

- (instancetype)initWithFrame:(CGRect)frame andColor:(UIColor *)color;
- (void)startAnimationWithCompletion:(ProgressCompletion)completionBlock;
- (void)reset;

@end
