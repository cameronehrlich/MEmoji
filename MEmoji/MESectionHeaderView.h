//
//  MESectionHeaderReusableView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

@class MESectionHeaderView;

@protocol MESectionHeaderViewDelegate <NSObject>
- (void)sectionHeader:(MESectionHeaderView *)header tappedButton:(UIButton *)sender;
@end

@interface MESectionHeaderView : UIView

- (instancetype)initWithFrame:(CGRect)frame withDelegate:(id<MESectionHeaderViewDelegate>)delegate;

@property (nonatomic, weak) id<MESectionHeaderViewDelegate> delegate;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *purchaseButton;

@end
