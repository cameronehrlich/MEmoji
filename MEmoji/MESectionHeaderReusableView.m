//
//  MESectionHeaderReusableView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MESectionHeaderReusableView.h"

@implementation MESectionHeaderReusableView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width/3, frame.size.height)];
//        [self.titleLabel setTextAlignment:NSTextAlignmentCenter];

        [self.titleLabel setText:@"Standard Pack"];
        [self addSubview:self.titleLabel];
        
        self.purchaseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.purchaseButton setFrame:CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height)];
        [self.purchaseButton setTitle:@"$0.99" forState:UIControlStateNormal];
        [self addSubview:self.purchaseButton];
    }
    return self;
}

@end
