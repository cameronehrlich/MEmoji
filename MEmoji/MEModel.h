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

#define Emoji_Size 200
#define Emoji_Padding Emoji_Size*0.75

static CGFloat stepOfGIF = 0.1f;

@interface MEModel : NSObject

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *fileOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) NSArray *currentImages; // Coredata Cache

@property (nonatomic, strong) NSMutableArray *currentFrames; //For collecting thumbnail images from MPMediaPlayer
@property (nonatomic, strong) MPMoviePlayerController *playerController; // For generating thumbnail images from video

@property (nonatomic, strong) NSOperationQueue *loadingQueue;
@property (nonatomic, strong) NSMutableDictionary *operationCache;
@property (copy) MemojiCallback completionBlock;

+ (instancetype)sharedInstance;

- (void)createEmojiFromMovieURL:(NSURL *)url complete:(MemojiCallback)callback;

- (NSData *)createGIFwithFrames:(NSArray *)images;

+ (NSString *)currentVideoPath;

@end
