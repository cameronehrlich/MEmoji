//
//  MEOverlayImage.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/23/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import Foundation;

@interface MEOverlayImage : NSObject

@property (strong, nonatomic) CALayer *layer;
@property (strong, nonatomic) UIImage *image;

- (instancetype)initWithImage:(UIImage *)image;

@end
