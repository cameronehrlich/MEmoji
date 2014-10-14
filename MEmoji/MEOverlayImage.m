//
//  MEOverlayImage.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/23/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEOverlayImage.h"

@interface MEOverlayImage ()

@property (nonatomic, strong) CALayer *layer;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *thumbnail;

@end

@implementation MEOverlayImage
{
    NSString *_imageName;
}

- (instancetype)initWithImageName:(NSString *)imageName;
{
    self = [super init];
    if (self) {
        _imageName = [imageName stringByReplacingOccurrencesOfString:@" " withString:@""];
        _thumbnail = [UIImage imageNamed:[NSString stringWithFormat:@"%@%@", _imageName, @"-thumbnail"]]; // 160x160
    }
    return self;
}
- (UIImage *)image
{
    if (!_image) {
        _image = [UIImage imageNamed:_imageName]; // 640x640
    }
    return _image;
}

- (CALayer *)layer
{
    if (!_layer || _layer.contents == nil) {
        _layer = [CALayer layer];
        _layer.contents = (id)self.image.CGImage; // Make sure the getter is called everytime to get the image.
    }
    return _layer;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ : \"%@\">", NSStringFromClass([self class]), _imageName];
}

@end
