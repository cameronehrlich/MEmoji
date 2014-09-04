//
//  MEModel.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <CoreData+MagicalRecord.h>
#import <UIImage+Additions.h>
#import <GPUImage.h>

#import "UIImage+Orientation.h"
#import "Image.h"

@import AVFoundation;
@import MediaPlayer;
@import ImageIO;
@import MobileCoreServices;

typedef void (^MemojiCallback)();

@interface MEModel : NSObject

@property (nonatomic, strong) NSArray *currentImages; // Coredata Cache

@property (nonatomic, strong) NSMutableArray *currentFrames; //For collecting thumbnail images from MPMediaPlayer
@property (nonatomic, strong) MPMoviePlayerController *playerController; // For generating thumbnail images from video

@property (nonatomic, strong) NSOperationQueue *loadingQueue;
@property (nonatomic, strong) NSMutableDictionary *operationCache;

+ (instancetype)sharedInstance;

- (void)createEmojiFromImage:(UIImage *)originalImage complete:(MemojiCallback)callback;
- (void)createEmojiFromMovieURL:(NSURL *)url complete:(MemojiCallback)callback;

- (UIImage *)rotateImage:(UIImage *)image onDegrees:(CGFloat)degrees;
- (UIImage *)paddedImageFromImage:(UIImage *)image;

@end
