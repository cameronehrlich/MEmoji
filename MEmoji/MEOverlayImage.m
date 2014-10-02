//
//  MEOverlayImage.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/23/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEOverlayImage.h"

@interface MEOverlayImage ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) CALayer *layer;

@end

@implementation MEOverlayImage
{
    NSString *_imageName;
}

- (instancetype)initWithImageName:(NSString *)imageName;
{
    self = [super init];
    if (self) {
        _imageName = imageName;
    }
    return self;
}
- (UIImage *)image
{
    if (!_image) {
        _image = [UIImage imageNamed:_imageName];
    }
    return _image;
}

- (CALayer *)layer
{
    if (!self.layer) {
        _layer = [CALayer layer];
        _layer.contents = (id)_image.CGImage;
        // MUST INDEPENDENTLY SET LAYER FRAME OR IT WONT WORK
    }
    
    return _layer;
}

@end
