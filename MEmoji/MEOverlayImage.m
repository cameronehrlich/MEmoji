//
//  MEOverlayImage.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/23/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEOverlayImage.h"

@implementation MEOverlayImage

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _image = image;
        _layer = [CALayer layer];
        _layer.contents = (id)_image.CGImage;
        // MUST INDEPENDENTLY SET LAYER FRAME OR IT WONT WORK
    }
    return self;
}

@end
