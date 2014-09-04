//
//  MEModel.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEModel.h"

#define Emoji_Size 200
#define Emoji_Padding Emoji_Size*0.75
static CGFloat stepOfGIF = 0.2f;

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
        
        self.operationCache = [NSMutableDictionary dictionary];

        self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
    }
    return self;
}


- (void)createEmojiFromImage:(UIImage *)originalImage complete:(MemojiCallback)callback
{
    NSDictionary *detectorOptions = @{CIDetectorAccuracy: CIDetectorAccuracyHigh};
    
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    NSDictionary *imageOptions = @{
                                   CIDetectorImageOrientation: @(6),
                                   CIDetectorSmile: @YES
                                   };
    
    CIImage *ciImage = [CIImage imageWithCGImage:originalImage.CGImage];
    
    NSArray *faceFeatures = [faceDetector featuresInImage:ciImage options:imageOptions];
    
    if (faceFeatures.count == 0) {
        NSLog(@"Not able to find bounds.");
        [[[UIAlertView alloc] initWithTitle:@"No Emotion Detected"
                                    message:@"Your face is missing."
                                   delegate:nil
                          cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        callback();
        return;
    }
    
    CGRect faceBounds;
    CGPoint leftEye, rightEye, mouthPosition;
    
    BOOL hasSmile = NO;
    
    for (CIFaceFeature *faceFeature in faceFeatures) {
        
        leftEye = faceFeature.leftEyePosition;
        rightEye = faceFeature.rightEyePosition;
        mouthPosition = faceFeature.mouthPosition;
        faceBounds = faceFeature.bounds;
        hasSmile = faceFeature.hasSmile;
        
        break;
    }
    
    // Get cropped image of just the face
    CGRect adjustedRect = faceBounds;
    
    // Translate bounds to account for mirroring
    CGFloat distanceFromCenter = CGRectGetMidY(faceBounds) - originalImage.size.width/2;
    
    if (distanceFromCenter > 0) {
        adjustedRect.origin.y -= MAX(0, 2 * ABS(distanceFromCenter));
    }else{
        adjustedRect.origin.y += 2 * ABS(distanceFromCenter);
    }
    
    CGFloat insetBasedOnEyeDistance = ABS(rightEye.y - leftEye.y)/3;
    
    adjustedRect = CGRectInset(adjustedRect, insetBasedOnEyeDistance, insetBasedOnEyeDistance);
    
    CGImageRef imref = CGImageCreateWithImageInRect([originalImage CGImage], adjustedRect);
    
    // Create UIImage
    UIImage *emojiImage = [UIImage imageWithCGImage:imref];
    
    CGImageRelease(imref);
    
    emojiImage = [self rotateImage:emojiImage onDegrees:90];
    
    emojiImage = [emojiImage imageWithCornerRadius:emojiImage.size.width/2];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Image *newImage = [Image MR_createInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setHasSmile:@(hasSmile)];
        [newImage setImageData:UIImagePNGRepresentation(emojiImage)];
        
    } completion:^(BOOL success, NSError *error) {
        
        self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
        callback();
    }];
}

- (void)createEmojiFromMovieURL:(NSURL *)url complete:(MemojiCallback)callback
{
    self.playerController = [[MPMoviePlayerController alloc] initWithContentURL:url];
    
    self.playerController.movieSourceType = MPMovieSourceTypeFile;
    self.playerController.shouldAutoplay = NO;
    
    // Begin conversion
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
    

    [[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {

        NSDictionary *userInfo = [note userInfo];
        
        UIImage *incomingFrame = [userInfo objectForKey:MPMoviePlayerThumbnailImageKey];

        CGRect cropRect = CGRectMake(0, (incomingFrame.size.height/2) - (incomingFrame.size.width/2), incomingFrame.size.width, incomingFrame.size.width);
        
        NSLog(@"croprect: %@", NSStringFromCGRect(cropRect));
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([incomingFrame CGImage], cropRect);
        incomingFrame = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        
        [self.currentFrames addObject:incomingFrame];
        
        if ([[userInfo objectForKey:MPMoviePlayerThumbnailTimeKey] floatValue] >= (duration.value/duration.timescale) - (2 * stepOfGIF)) {
            [self.playerController cancelAllThumbnailImageRequests];
            
            NSData *gifData = [self createGIFwithFrames:[self.currentFrames copy]];
            
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Image *newImage = [Image MR_createInContext:localContext];
                [newImage setCreatedAt:[NSDate date]];
                [newImage setImageData:gifData];
                [newImage setIsAnimated:@YES];
                
            } completion:^(BOOL success, NSError *error) {
                
                self.currentImages = [Image MR_findAllSortedBy:@"createdAt" ascending:NO];
                callback();
            }];
        }
    }];
}


- (UIImage *)paddedImageFromImage:(UIImage *)image
{
    // Scale image down
    UIGraphicsBeginImageContext(CGSizeMake(Emoji_Size + Emoji_Padding, Emoji_Size + Emoji_Padding));
    
    [image drawInRect:CGRectMake(Emoji_Padding/2, Emoji_Padding/2, Emoji_Size, Emoji_Size)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)rotateImage:(UIImage *)image onDegrees:(CGFloat)degrees
{
    CGFloat rads = M_PI * degrees / 180;
    CGFloat newSide = MAX([image size].width, [image size].height);
    CGSize size =  CGSizeMake(newSide, newSide);
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, newSide/2, newSide/2);
    CGContextRotateCTM(ctx, rads);
    CGContextDrawImage(UIGraphicsGetCurrentContext(),CGRectMake(-[image size].width/2,-[image size].height/2,size.width, size.height),image.CGImage);
    UIImage *i = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return i;
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



@end
