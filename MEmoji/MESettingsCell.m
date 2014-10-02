//
//  MESettingsCell.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 10/1/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MESettingsCell.h"

@implementation MESettingsCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.selectedBackgroundView = [[UIView alloc] init];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [self setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3]];
    }else{
        [self setBackgroundColor:[UIColor clearColor]];
    }

}

@end
