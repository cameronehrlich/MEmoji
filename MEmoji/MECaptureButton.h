//
//  MECaptureButton.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import Foundation;
#import <LLARingSpinnerView.h>

const static CGFloat captureButtonDiameter = 90.0;

@interface MECaptureButton : UIView

@property (nonatomic, strong) CALayer *backgroundLayer;
@property (nonatomic, strong) LLARingSpinnerView *spinnerView;

@property (nonatomic, assign) NSInteger rangeOfMotion;
@property (nonatomic, assign) CGAffineTransform scaleTransform;

- (void)startSpinning;
- (void)stopSpinning;

- (void)scaleUp;
- (void)scaleDown;

@end
