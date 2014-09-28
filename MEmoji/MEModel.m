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
        
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        self.currentOverlays = [[NSMutableArray alloc] init];
        
        self.movieRenderingQueue = [[NSOperationQueue alloc] init];
        [self.movieRenderingQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        [self initializeCaptureSession];
    }
    return self;
}

- (void)reloadCurrentImages
{
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
}

- (void)createEmojiFromMovieURL:(NSURL *)url andOverlays:(NSArray *)overlays complete:(MEmojiCallback)callback
{
    self.completionBlock = callback;
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [generator setRequestedTimeToleranceAfter:kCMTimeZero];
    [generator setRequestedTimeToleranceBefore:kCMTimeZero];
    [generator setAppliesPreferredTrackTransform:YES];
    [generator setMaximumSize:CGSizeMake(dimensionOfGIF, 2 * dimensionOfGIF)];
    
    CMTime duration = asset.duration;
    
    NSMutableArray *outImages = [[NSMutableArray alloc] init];
    NSError *error;
    
    NSInteger frameRate = 80;
    
    for (NSInteger frame = 0; frame < duration.value; frame += frameRate) {
        @autoreleasepool {
            CMTime keyFrame = CMTimeMake((Float64)frame, duration.timescale);
            
            CMTime actualTime;
            CGImageRef refImg = [generator copyCGImageAtTime:keyFrame actualTime:&actualTime error:&error];
            
            UIImage *singleFrame = [UIImage imageWithCGImage:refImg scale:1 orientation:UIImageOrientationUp];
            
            BOOL isBackFacing = (self.inputDevice.device == self.backCamera);
            if (isBackFacing) {
                // Flip image only if using back camera
                singleFrame = [self flippedImageAxis:singleFrame];
            }
            
            UIImage *tmpFrameImage = [self emojifyFrame:singleFrame andOverlays:overlays];
            
            [outImages addObject:tmpFrameImage];
            
            if (error) {
                NSLog(@"Frame generation error: %@", error);
                break;
            }
        }
    }
    
    NSArray *emojifiedFrames = [outImages copy];
    
    NSData *GIFData = [self createGIFwithFrames:emojifiedFrames];
    
    if (GIFData == nil) {
        NSLog(@"Trying to save nil gif!");
    }
    
    __block Image *justSaved;
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Image *newImage = [Image MR_createInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setImageData:GIFData];
        justSaved = newImage;

    } completion:^(BOOL success, NSError *error) {
        self.selectedImage = justSaved;
        self.completionBlock();
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.movieRenderingQueue addOperationWithBlock:^{
                self.movieMaker = [[CEMovieMaker alloc] initWithSettings:[CEMovieMaker videoSettingsWithCodec:AVVideoCodecH264
                                                                                                    withWidth:dimensionOfGIF
                                                                                                    andHeight:dimensionOfGIF]];
                
                NSArray *framesTimes3 = [[emojifiedFrames arrayByAddingObjectsFromArray:emojifiedFrames] arrayByAddingObjectsFromArray:emojifiedFrames];
                
                [self.movieMaker createMovieFromImages:framesTimes3 withCompletion:^(BOOL success, NSURL *fileURL) {
                    if (!success) {
                        NSLog(@"There was an error creating the movie");
                    }
                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                        NSData *movieData = [NSData dataWithContentsOfURL:fileURL];
                        
                        [[justSaved MR_inContext:localContext] setMovieData:movieData];
                        
                    } completion:^(BOOL success, NSError *error) {
                        if (error || !success) {
                            NSLog(@"Error while saving movie: %@", error);
                        }else{
                            NSLog(@"Finished saving movie data.");
                        }
                    }];
                }];
            }];
            
        });
    }];
}

- (UIImage *)emojifyFrame:(UIImage *)imgFrame andOverlays:(NSArray *)overlays
{
    CGRect cropRect = CGRectMake(0, (imgFrame.size.height/2) - (imgFrame.size.width/2), imgFrame.size.width, imgFrame.size.width);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([imgFrame CGImage], cropRect);
    imgFrame = [UIImage imageWithCGImage:imageRef scale:1 orientation:UIImageOrientationUpMirrored];
    CGImageRelease(imageRef);
    
    for (UIImage *overlay in overlays) {
        imgFrame = [self image:imgFrame withOverlay:overlay];
    }
    
    return imgFrame;
}


- (UIImage *)image:(UIImage *)image withOverlay:(UIImage *)overlay
{
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 1);
    
    [image drawInRect:CGRectMake( 0, 0, dimensionOfGIF, dimensionOfGIF)];
    [overlay drawInRect:CGRectMake( 0, 0, dimensionOfGIF, dimensionOfGIF)];

    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return destImage;
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

- (UIImage *)flippedImageAxis:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 1);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // flip x
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);

    // then flip Y axis
    CGContextTranslateCTM(context, image.size.width, 0);
    CGContextScaleCTM(context, -1.0f, 1.0f);
    
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, image.size.width, image.size.height), [image CGImage]);
    
    UIImage *flipedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return flipedImage;
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

+ (NSArray *)allOverlays
{
    static NSArray *allImages = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        NSArray *imageNames = @[
                                @"Fistwhite",
                                @"cartoonOuchie",
                                @"doubleFist",
                                @"faceGrampa",
                                @"halfCigarette",
                                @"maitaiGlass",
                                @"playViola",
                                @"sexyLips",
                                @"thumbLeft",
                                @"cheekKiss",
                                @"downThumb",
                                @"faceMom",
                                @"handsPalms",
                                @"martiniGlass",
                                @"pointOut",
                                @"sexySaxy",
                                @"toiletFace",
                                @"ambiguosHands",
                                @"cheerCone",
                                @"dropBass",
                                @"faceMustache",
                                @"heartEyes",
                                @"medicalHat",
                                @"pointUp",
                                @"showerHead",
                                @"tongueLaugh",
                                @"babyBottle",
                                @"cherriesSex",
                                @"embrellaRain",
                                @"faceNO",
                                @"itsDoodoo",
                                @"moneyBag",
                                @"policeHat",
                                @"sleepZees",
                                @"topHat",
                                @"balloonRed",
                                @"chinaHat",
                                @"exclamationPoint",
                                @"faceQueen",
                                @"kittyWhiskers",
                                @"monkeySpeak",
                                @"prayingHands",
                                @"smallCamera",
                                @"turbanAllah",
                                @"beerMug",
                                @"clapHands",
                                @"eyes",
                                @"faceSkull",
                                @"knifeParty",
                                @"musicNotes",
                                @"pumkinHead",
                                @"smallTears",
                                @"waterMelon",
                                @"bigFist",
                                @"clapMarker",
                                @"faceBaby",
                                @"fireFire",
                                @"leftFist",
                                @"nostrilSmoke",
                                @"questionMark",
                                @"soundMic",
                                @"waterfallTears",
                                @"bigLaugh",
                                @"creepyEyes",
                                @"faceBoy",
                                @"ghostEyes",
                                @"lightBulb",
                                @"oneTear",
                                @"rightThumb",
                                @"strongArms",
                                @"wineGlass",
                                @"bigPhone",
                                @"daBomb",
                                @"faceDemon",
                                @"goldCrown",
                                @"lightningBolt",
                                @"peaceHand",
                                @"roseRed",
                                @"surgicalMask",
                                @"bigTears",
                                @"darkGun",
                                @"faceGirl",
                                @"graduationCap",
                                @"lolliPop",
                                @"pigNose",
                                @"russianHat",
                                @"sunGlasses",
                                @"blueHalo",
                                @"donaldTrumpet",
                                @"faceGramma",
                                @"gritTeeth",
                                @"loudSpeaker",
                                @"pinkBow",
                                @"santaHatBeard",
                                @"theTrophy"];
        
        NSMutableArray *outputImages = [[NSMutableArray alloc] initWithCapacity:imageNames.count];

        for (NSString *name in imageNames) {
            @autoreleasepool {
                MEOverlayImage *tmpImage = [[MEOverlayImage alloc] initWithImage:[UIImage imageNamed:name]];
                [outputImages addObject:tmpImage];
            }
        }
        
        allImages = [outputImages copy];
    });
    
    return allImages;
}

+ (UIColor *)mainColor
{
    static UIColor *mainColor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainColor = [UIColor colorWithHex:0x49a5db];
    });
    
    return mainColor;
}

+ (UIFont *)mainFontWithSize:(NSInteger)size
{
    // Make static?
    return [UIFont fontWithName:@"AvenirNext-Medium" size:size];
}

@end
