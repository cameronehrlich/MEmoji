//
//  MEIntroductionView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 10/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

@class MEIntroductionView;

@protocol MEIntroductionViewDelegate <NSObject>

- (void)introductionViewDidComplete;

@end

@interface MEIntroductionView : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) id<MEIntroductionViewDelegate> delegate;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIScrollView *scrollView;

@end
