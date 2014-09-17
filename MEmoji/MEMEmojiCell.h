//
//  MEMEmojiCell.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <FLAnimatedImageView.h>

@interface MEMEmojiCell : UICollectionViewCell

@property (strong, nonatomic) FLAnimatedImageView *imageView;
@property (strong, nonatomic) UIImageView *deleteImageView;
@property (assign, nonatomic) BOOL editMode;

@end
