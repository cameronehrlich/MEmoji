//
//  MEOverlayImage.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/23/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import Foundation;

@interface MEOverlayImage : NSObject

@property (strong, nonatomic, readonly) CALayer *layer;
@property (strong, nonatomic, readonly) UIImage *image;
@property (strong, nonatomic, readonly) UIImage *thumbnail;

- (instancetype)initWithImageName:(NSString *)imageName;

@end
