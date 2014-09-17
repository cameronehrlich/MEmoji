//
//  MEModel.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <CoreData+MagicalRecord.h>
#import <UIImage+Additions.h>
#import "CEMovieMaker.h"
#import "Image.h"

@import AVFoundation;
@import MediaPlayer;
@import ImageIO;
@import MobileCoreServices;

typedef void (^MEmojiCallback)();

static const CGFloat dimensionOfGIF = 320;
static const CGFloat stepOfGIF = 0.12f;
static const CGFloat marginOfGIF = 0.40f;

@interface MEModel : NSObject

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;

@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *fileOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CEMovieMaker *movieMaker;


@property (nonatomic, strong) NSMutableArray *currentFrames; //For collecting thumbnail images from MPMediaPlayer
@property (nonatomic, strong) MPMoviePlayerController *playerController; // For generating thumbnail images from video

@property (nonatomic, strong) NSOperationQueue *loadingQueue;
@property (copy) MEmojiCallback completionBlock;

+ (instancetype)sharedInstance;
+ (NSString *)currentVideoPath;

- (void)createEmojiFromMovieURL:(NSURL *)url andOverlays:(NSArray *)overlays complete:(MEmojiCallback)callback;
- (NSData *)createGIFwithFrames:(NSArray *)images;
- (void)toggleCameras;

+ (NSArray *)allOverlays;

@end
