//
//  MEModel.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreData+MagicalRecord.h>
#import <UIImage+Additions.h>
#import <GPUImage.h>

#import "UIImage+Orientation.h"
#import "Image.h"

typedef void (^MemojiCallback)();

@interface MEModel : NSObject

@property (nonatomic, strong) NSArray *currentImages;

+ (instancetype)sharedInstance;

- (void)createEmojiFromImage:(UIImage *)originalImage complete:(MemojiCallback)callback;
- (UIImage *)rotateImage:(UIImage *)image onDegrees:(CGFloat)degrees;
- (UIImage *)paddedImageFromImage:(UIImage *)image;


@end
