//
//  MEFlowLayout.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/5/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

/// The default resistance factor that determines the bounce of the collection. Default is 900.0f.
#define kScrollResistanceFactorDefault 900.0f;

@interface MEFlowLayout : UICollectionViewFlowLayout

/// The dynamic animator used to animate the collection's bounce
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;

// Needed for tiling
@property (nonatomic, strong) NSMutableSet *visibleIndexPathsSet;
@property (nonatomic, strong) NSMutableSet *visibleHeaderAndFooterSet;
@property (nonatomic, assign) CGFloat latestDelta;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

/// The scrolling resistance factor determines how much bounce / resistance the collection has. A higher number is less bouncy, a lower number is more bouncy. The default is 900.0f.
@property (nonatomic, assign) CGFloat scrollResistanceFactor;

@end
