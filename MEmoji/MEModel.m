//
//  MEModel.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEModel.h"

@implementation MEModel

+ (instancetype)sharedInstance
{
    static MEModel *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MEModel alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [MagicalRecord setupAutoMigratingCoreDataStack];
        
        self.loadingQueue = [[NSOperationQueue alloc] init];
        [self.loadingQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initializeCaptureSession];
        });
    }
    return self;
}

- (void)createEmojiFromMovieURL:(NSURL *)url complete:(MEmojiCallback)callback
{
    self.completionBlock = callback;
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [generator setRequestedTimeToleranceAfter:kCMTimeZero];
    [generator setRequestedTimeToleranceBefore:kCMTimeZero];
    [generator setAppliesPreferredTrackTransform:YES];
    [generator setMaximumSize:CGSizeMake(dimensionOfGIF, dimensionOfGIF)];
    
    CMTime duration = asset.duration;

    NSMutableArray *outImages = [[NSMutableArray alloc] init];
    NSError *error;
    
    NSInteger frameRate = 80;
    
    for (NSInteger frame = 0; frame < duration.value; frame += frameRate) {
        @autoreleasepool {
            CMTime keyFrame = CMTimeMake( (Float64)frame ,duration.timescale);
            
            CMTime actualTime;
            CGImageRef refImg = [generator copyCGImageAtTime:keyFrame actualTime:&actualTime error:&error];
//            NSLog(@"Attempted: %lld / %d, Got: %lld / %d", keyFrame.value, keyFrame.timescale, actualTime.value, actualTime.timescale);
            UIImage *tmpFrameImage = [self emojifyFrame:[UIImage imageWithCGImage:refImg]];
            
            [outImages addObject:tmpFrameImage];
            
            if (error) {
                NSLog(@"Frame generation error: %@", error);
                break;
            }
        }
    }
    
    NSData *gifData = [self createGIFwithFrames:[outImages copy]];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        Image *newImage = [Image MR_createInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setImageData:gifData];
        [newImage setIsAnimated:@YES];
        
    } completion:^(BOOL success, NSError *error) {
        
        self.completionBlock();
    }];
}

- (UIImage *)emojifyFrame:(UIImage *)incomingFrame
{
    CGRect cropRect = CGRectMake(0, (incomingFrame.size.height/2) - (incomingFrame.size.width/2), incomingFrame.size.width, incomingFrame.size.width);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([incomingFrame CGImage], cropRect);
    incomingFrame = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    incomingFrame = [incomingFrame imageWithCornerRadius:incomingFrame.size.width/2];
    
    incomingFrame = [UIImage imageWithCGImage:incomingFrame.CGImage scale:incomingFrame.scale orientation:incomingFrame.scale];
    
    incomingFrame = [self imageWithBorder:incomingFrame.size.width*marginOfGIF FromImage:incomingFrame];
    
    return incomingFrame;
}

- (NSData *)createGIFwithFrames:(NSArray *)images
{
    NSDictionary *fileProperties = @{
                                     (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
                                             }
                                     };
    
    NSDictionary *frameProperties = @{
                                      (__bridge id)kCGImagePropertyGIFDictionary: @{
                                              (__bridge id)kCGImagePropertyGIFDelayTime:[NSNumber numberWithFloat:stepOfGIF], // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                              }
                                      };
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, images.count, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    @autoreleasepool {
        for (UIImage *image in images ) {
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    NSData *gifData = [NSData dataWithContentsOfFile:fileURL.relativePath];
    return gifData;
}


- (UIImage*)imageWithBorder:(CGFloat)margin FromImage:(UIImage*)source
{
    CGSize size = CGSizeMake([source size].width + 2*margin, [source size].height + 2*margin);
    UIGraphicsBeginImageContextWithOptions(size, YES, source.scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect entireRect = CGRectMake(-margin, -margin, size.width + margin*margin, size.height + margin*margin);
    CGContextClearRect(context, entireRect);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, entireRect);
    
    CGRect rect = CGRectMake(margin, margin, size.width-2*margin, size.height-2*margin);
    [source drawInRect:rect];
    
    UIImage *testImg =  UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    return testImg;
}

#pragma mark -
#pragma mark AVFoundation Setup
- (void)initializeCaptureSession
{
    self.session = [[AVCaptureSession alloc] init];
    
    [self initializeCameraReferences];
    
    self.fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self.session addOutput:self.fileOutput];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [self.session startRunning];
    
    [self beginRecordingWithDevice:self.frontCamera];
}

- (void)initializeCameraReferences
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for(AVCaptureDevice *device in devices)
    {
        if(device.position == AVCaptureDevicePositionBack)
        {
            self.backCamera = device;
        }
        else if(device.position == AVCaptureDevicePositionFront)
        {
            self.frontCamera = device;
        }
    }
}

- (void)beginRecordingWithDevice:(AVCaptureDevice *)device
{
    [self.session stopRunning];
    
    if (self.inputDevice)
    {
        [self.session removeInput:self.inputDevice];
    }
    
    NSError *error = nil;
    self.inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
        return;
    }
    
    [self.session addInput:self.inputDevice];
    
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    [self.session startRunning];
    
}

- (void)toggleCameras
{
    BOOL isBackFacing = (self.inputDevice.device == self.backCamera);
    [self.session stopRunning];
    
    if (isBackFacing)
    {
        [self beginRecordingWithDevice:self.frontCamera];
    }
    else
    {
        [self beginRecordingWithDevice:self.backCamera];
    }
}

+ (NSString *)currentVideoPath
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = directories.firstObject;
    NSString *absolutePath = [directory stringByAppendingPathComponent:@"/current.mov"];
    
    return absolutePath;
}

@end
