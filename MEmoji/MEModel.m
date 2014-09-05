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
        [self.loadingQueue setMaxConcurrentOperationCount:1];
        
        self.operationCache = [NSMutableDictionary dictionary];
        self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initializeCaptureSession];
        });
    }
    return self;
}

- (void)createEmojiFromMovieURL:(NSURL *)url complete:(MemojiCallback)callback
{
    self.completionBlock = callback;
    
    self.playerController = [[MPMoviePlayerController alloc] initWithContentURL:url];
    
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:url];
    CMTime duration = [avUrl duration];
    
    self.currentFrames = [NSMutableArray array];
    NSMutableArray *keyFrames = [NSMutableArray array];
    
    float current = 0.0f;
    
    while (current <= duration.value/duration.timescale)
    {
        [keyFrames addObject:[NSNumber numberWithFloat:current]];
        current += stepOfGIF;
    }
    
    [self.playerController requestThumbnailImagesAtTimes:keyFrames timeOption:MPMovieTimeOptionExact];
    
    __block BOOL stop = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        
        NSDictionary *userInfo = [note userInfo];
        
        UIImage *incomingFrame = [userInfo objectForKey:MPMoviePlayerThumbnailImageKey];
        
        incomingFrame = [self emojifyFrame:incomingFrame];
        
        [self.currentFrames addObject:incomingFrame];
        
        float time = [[userInfo objectForKey:MPMoviePlayerThumbnailTimeKey] floatValue];
        if ( time >= (duration.value/duration.timescale) - (4 * stepOfGIF) ) {
            // Done receiving frames
            NSLog(@"Received all frames");
            if (stop) {
                NSLog(@"STOP!");
                self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
                self.completionBlock();
                return;
            }
            
            stop = YES;
            
            [self.playerController cancelAllThumbnailImageRequests];
            self.playerController = nil;
            NSData *gifData = [self createGIFwithFrames:self.currentFrames];
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                
                Image *newImage = [Image MR_createInContext:localContext];
                [newImage setCreatedAt:[NSDate date]];
                [newImage setImageData:gifData];
                [newImage setIsAnimated:@YES];
                
            } completion:^(BOOL success, NSError *error) {
                
                self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
                self.completionBlock();
                
            }];
        }
    }];
}

- (UIImage *)emojifyFrame:(UIImage *)incomingFrame
{
    CGRect cropRect = CGRectMake(0, (incomingFrame.size.height/2) - (incomingFrame.size.width/2), incomingFrame.size.width, incomingFrame.size.width);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([incomingFrame CGImage], cropRect);
    incomingFrame = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    incomingFrame = [incomingFrame imageWithCornerRadius:incomingFrame.size.width/2];
    
    incomingFrame = [UIImage imageWithCGImage:incomingFrame.CGImage scale:4 orientation:incomingFrame.scale];
    
    incomingFrame = [self imageWithBorderFromImage:incomingFrame];
    
//    incomingFrame = [self paddedImageFromImage:incomingFrame];
    
    return incomingFrame;
}

- (UIImage *)paddedImageFromImage:(UIImage *)image
{
    // Scale image down
    UIGraphicsBeginImageContext(CGSizeMake(Emoji_Size + Emoji_Padding, Emoji_Size + Emoji_Padding));
    
    CGContextSaveGState(UIGraphicsGetCurrentContext());
    
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, image.size.height/2);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, Emoji_Size, Emoji_Size), image.CGImage);

    CGContextRestoreGState(UIGraphicsGetCurrentContext());

    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
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


- (UIImage*)imageWithBorderFromImage:(UIImage*)source
{
    const CGFloat margin = 40.0f;
    CGSize size = CGSizeMake([source size].width + 2*margin, [source size].height + 2*margin);
    UIGraphicsBeginImageContextWithOptions(size, YES, source.scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    [[UIColor whiteColor] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)] fill];
    
    CGRect rect = CGRectMake(margin, margin, size.width-2*margin, size.height-2*margin);
    [source drawInRect:rect blendMode:kCGBlendModeNormal alpha:1.0];
    
    UIImage *testImg =  UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    return testImg;
}

//NSDictionary *detectorOptions = @{CIDetectorAccuracy: CIDetectorAccuracyHigh};
//
//CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
//
//NSDictionary *imageOptions = @{
//                               CIDetectorImageOrientation: @(6),
//                               CIDetectorSmile: @YES
//                               };
//
//CIImage *ciImage = [CIImage imageWithCGImage:originalImage.CGImage];
//
//NSArray *faceFeatures = [faceDetector featuresInImage:ciImage options:imageOptions];
//
//if (faceFeatures.count == 0) {
//    NSLog(@"Not able to find bounds.");
//    [[[UIAlertView alloc] initWithTitle:@"No Emotion Detected"
//                                message:@"Your face is missing."
//                               delegate:nil
//                      cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
//    callback();
//    return;
//}
//
//CGRect faceBounds;
//CGPoint leftEye, rightEye, mouthPosition;
//
//BOOL hasSmile = NO;
//
//for (CIFaceFeature *faceFeature in faceFeatures) {
//
//    leftEye = faceFeature.leftEyePosition;
//    rightEye = faceFeature.rightEyePosition;
//    mouthPosition = faceFeature.mouthPosition;
//    faceBounds = faceFeature.bounds;
//    hasSmile = faceFeature.hasSmile;
//
//    break;
//}
//
//// Get cropped image of just the face
//CGRect adjustedRect = faceBounds;
//
//// Translate bounds to account for mirroring
//CGFloat distanceFromCenter = CGRectGetMidY(faceBounds) - originalImage.size.width/2;
//
//if (distanceFromCenter > 0) {
//    adjustedRect.origin.y -= MAX(0, 2 * ABS(distanceFromCenter));
//}else{
//    adjustedRect.origin.y += 2 * ABS(distanceFromCenter);
//}
//
//CGFloat insetBasedOnEyeDistance = ABS(rightEye.y - leftEye.y)/3;
//
//adjustedRect = CGRectInset(adjustedRect, insetBasedOnEyeDistance, insetBasedOnEyeDistance);
//
//CGImageRef imref = CGImageCreateWithImageInRect([originalImage CGImage], adjustedRect);
//
//// Create UIImage
//UIImage *emojiImage = [UIImage imageWithCGImage:imref];
//
//CGImageRelease(imref);
//
//emojiImage = [self rotateImage:emojiImage onDegrees:90];
//emojiImage = [emojiImage imageWithCornerRadius:emojiImage.size.width/2];

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
