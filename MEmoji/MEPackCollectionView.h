//
//  MEPackCollectionView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 11/9/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

static NSString *CellReuseIdentifier = @"MEmojiCell";

#import "MESectionsManager.h"

@interface MEPackCollectionView : UICollectionView

- (instancetype)initWithFrame:(CGRect)frame andSectionManager:(MESectionsManager *)sectionsManager;

@end
