//
//  MEViewFinder.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/26/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

@class MEViewFinder;

@protocol MEViewFinderDelegate <NSObject>

- (void)viewFinder:(MEViewFinder *)viewFinder didTapButton:(UIButton *)button;

@end

@interface MEViewFinder : UIView

@property (nonatomic, weak) id<MEViewFinderDelegate> delegate;

@property (nonatomic, strong) CALayer *previewLayer;
@property (nonatomic, strong) CALayer *maskLayer;

@property (nonatomic, strong) UIButton *topLeftButton;
@property (nonatomic, strong) UIButton *topRightButton;
@property (nonatomic, strong) UIButton *bottomLeftButton;
@property (nonatomic, strong) UIButton *bottomRightButton;

@property (nonatomic, strong, readonly) NSArray *allButtons;

@property (nonatomic, assign) BOOL showingMask;

- (instancetype)initWithFrame:(CGRect)frame previewLayer:(CALayer *)previewLayer;

@end
