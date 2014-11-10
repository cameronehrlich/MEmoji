//
//  MEPackCollectionView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 11/9/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEOverlayCell.h"
#import "MEPackCollectionView.h"

@implementation MEPackCollectionView

- (instancetype)initWithFrame:(CGRect)frame andSectionManager:(MESectionsManager *)sectionsManager
{
    self = [super initWithFrame:frame collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    if (self) {
        // configure
        self.backgroundColor = [UIColor clearColor];
        [self registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
        [self setDelegate:sectionsManager];
        [self setDataSource:sectionsManager];
        [self setAlwaysBounceVertical:YES];
        [self setAllowsMultipleSelection:YES];
    }
    return self;
}

@end
