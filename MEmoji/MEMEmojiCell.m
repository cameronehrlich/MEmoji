//
//  MEMEmojiCell.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEMEmojiCell.h"

@implementation MEMEmojiCell

- (void)prepareForReuse
{
    self.imageView.image = nil;
}

@end
