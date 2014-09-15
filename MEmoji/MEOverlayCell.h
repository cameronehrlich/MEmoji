//
//  MEOverlayCellCollectionViewCell.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/15/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MEOverlayCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *selectedImageView;
@property (strong, nonatomic) UIImageView *maskingView;
@property (strong, nonatomic) UIImageView *imageView;

@end
