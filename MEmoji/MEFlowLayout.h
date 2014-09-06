//
//  MEFlowLayout.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/5/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MEFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, assign) CGFloat springDamping;
@property (nonatomic, assign) CGFloat springFrequency;
@property (nonatomic, assign) CGFloat resistanceFactor;

@end
