//
//  MESectionsScrollView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

@protocol MESectionsScrollViewDelegate <NSObject>

- (NSInteger)numberOfSections;

@end

@interface MESectionsScrollView : UIScrollView

@end
