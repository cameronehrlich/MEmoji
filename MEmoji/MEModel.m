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
    return [UIFont fontWithName:@"ArialRoundedMTBold" size:size];
}

+ (NSString *)formattedPriceForProduct:(SKProduct *)product
{
    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
    [priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [priceFormatter setLocale:product.priceLocale];
    NSString *price = [priceFormatter stringFromNumber:product.price];
    return price;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [MagicalRecord setupAutoMigratingCoreDataStack];
        [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
        
        [self initializeCaptureSession];
        
        self.numberToLoad = numberToLoadIncrementValue;
        self.currentOverlays = [[NSMutableArray alloc] init];
        
        self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:hipHopPackProductIdentifier, nil]];
        [self.productRequest setDelegate:self];
        [self.productRequest start];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        self.HUD = [[JGProgressHUD alloc] initWithStyle:JGProgressHUDStyleLight];
    }
    return self;
}

- (NSArray *)currentImages
{
    if (_currentImages == nil) {
        [self reloadCurrentImages];
    }
    return _currentImages;
}

- (void)reloadCurrentImages
{
    NSFetchRequest *fetchRequest = [Image MR_requestAllSortedBy:@"createdAt" ascending:NO inContext:[NSManagedObjectContext MR_defaultContext]];
    [fetchRequest setFetchLimit:MIN(numberOfGIFsToKeep, self.numberToLoad)];
    self.currentImages = [Image MR_executeFetchRequest:fetchRequest];

    if ([Image MR_countOfEntitiesWithContext:[NSManagedObjectContext MR_defaultContext]] > numberOfGIFsToKeep) {

        NSArray *reversedObjects = [Image MR_executeFetchRequest:fetchRequest];
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            for (NSInteger i = reversedObjects.count-1; i > numberOfGIFsToKeep-1; i--) {
                [[reversedObjects objectAtIndex:i] MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            }
        } completion:^(BOOL contextDidSave, NSError *error) {
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"Deleted old shit");
            }];

        }];
    }
    
}

- (void)createImageAnimated:(BOOL)animated withOverlays:(NSArray *)overlays complete:(MEmojiCreationCallback)callback
{
    self.creationCompletion = callback;
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[MEModel currentVideoPath]]
                                            options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [generator setRequestedTimeToleranceAfter:kCMTimeZero];
    [generator setRequestedTimeToleranceBefore:kCMTimeZero];
    [generator setAppliesPreferredTrackTransform:YES];
    [generator setMaximumSize:CGSizeMake(dimensionOfGIF, 2 * dimensionOfGIF)];
    
    CMTime duration = asset.duration;
    
    NSMutableArray *outImages = [[NSMutableArray alloc] init];
    NSError *error;
    
    const static NSInteger frameRate = 80;
    
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
            const CGRect cropRect = CGRectMake(0, (singleFrame.size.height/2) - (singleFrame.size.width/2), singleFrame.size.width, singleFrame.size.width);
            
            UIImage *croppedImage = [self cropImage:singleFrame toRect:cropRect];
            UIImage *tmpFrameImage = [self emojifyFrame:croppedImage andOverlays:overlays];
            
            [outImages addObject:tmpFrameImage];
            
            if (error) {
                NSLog(@"Frame generation error: %@", error);
                break;
            }
        }
    }
    
    NSArray *emojifiedFrames = [outImages copy];
    
    NSData *GIFData = [self createGIFwithFrames:emojifiedFrames];
    NSData *frameData = [NSKeyedArchiver archivedDataWithRootObject:emojifiedFrames];
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Image *newImage = [Image MR_createEntityInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setImageData:GIFData];
        [newImage setFrameData:frameData]; // TODO : Create video only when its needed
        [newImage setAnimated:@(animated)];
        self.selectedImage = newImage;
        
    } completion:^(BOOL success, NSError *error) {
        self.creationCompletion();
    }];
}

- (void)saveMovieFromImage:(Image*)image withCompletion:(SaveCallback)completion
{
    self.saveCompletion = completion;
    if (![image.animated boolValue]) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"Non-animated GIFs can't be saved as videos...Silly!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
        [[MEModel sharedInstance].HUD dismissAnimated:YES];
        self.saveCompletion(NO);
    }else{
        self.movieMaker = [[CEMovieMaker alloc] initWithSettings:[CEMovieMaker videoSettingsWithCodec:AVVideoCodecH264
                                                                                            withWidth:dimensionOfGIF
                                                                                            andHeight:dimensionOfGIF]];
        NSArray *frames = [NSKeyedUnarchiver unarchiveObjectWithData:image.frameData];
        
        NSMutableArray *framesMultiplied = [[NSMutableArray alloc] initWithCapacity:frames.count*numberOfGIFVideoLoops];
        
        for (NSInteger i = 0; i <= numberOfGIFVideoLoops; i++) {
            [framesMultiplied addObjectsFromArray:frames];
        }
        
        [self.movieMaker createMovieFromImages:[framesMultiplied copy] withCompletion:^(NSURL *fileURL) {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    NSLog(@"Error saving movie to Asset Library: %@", error.debugDescription);
                }
                if (self.saveCompletion) {
                    self.saveCompletion(YES);
                }
            }];
        }];
    }
}

- (UIImage *)emojifyFrame:(UIImage *)imgFrame andOverlays:(NSArray *)overlays
{
    UIGraphicsBeginImageContextWithOptions(imgFrame.size, YES, 1.0);
    
    [imgFrame drawInRect:CGRectMake( 0, 0, dimensionOfGIF, dimensionOfGIF)];
    
    for (UIImage *overlay in overlays) {
        [overlay drawInRect:CGRectMake( 0, 0, dimensionOfGIF, dimensionOfGIF)];
    }
    
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return destImage;
}

- (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *imgFrame = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUpMirrored];
    CGImageRelease(imageRef);
    
    return imgFrame;
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
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil]; //TODO : Proper error checking here?
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
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 1.0);
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
    
    // Video
    self.videoFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self.session addOutput:self.videoFileOutput];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [self.session startRunning];
    [self beginRecordingWithDevice:self.frontCamera];
}

- (void)initializeCameraReferences
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == AVCaptureDevicePositionBack)
        {
            self.backCamera = device;
        }
        else if (device.position == AVCaptureDevicePositionFront)
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
    
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
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

+ (NSArray *)standardPack
{
    static NSArray *allImages = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSArray *imageNames = @[
                                @"smallTears",
                                @"goldCrown",
                                @"kittyWhiskers",
                                @"nerdGlasses",
                                @"itsDoodoo",
                                @"prayingHands",
                                @"blackPrayingHands",
                                @"eyes",
                                @"creepyEyes",
                                @"stonerEyes",
                                @"blackEyes",
                                @"sunGlasses",
                                @"heartEyes",
                                @"heartArrow",
                                @"heartBroke",
                                @"cheekKiss",
                                @"sexyLips",
                                @"gritTeeth",
                                @"nostrilSmoke",
                                @"tongueLaugh",
                                @"bigLaugh.jpg",
                                @"oneTear",
                                @"bigTears",
                                @"waterfallTears",
                                @"monkeySpeak",
                                @"pigNose",
                                @"santaHatBeard",
                                @"toiletFace",
                                @"afroHair",
                                @"flatTop",
                                @"mohawkBlack",
                                @"mohawkBlonde",
                                @"mustacheNewerThinnerVersion",
                                @"oldTimeyMustache",
                                @"blueHalo",
                                @"pinkBow",
                                @"topHat",
                                @"turbanAllah",
                                @"graduationCap",
                                @"policeHat",
                                @"russianHat",
                                @"chinaHat",
                                @"surgicalMask",
                                @"fmlForehead",
                                @"halfCigarette",
                                @"showerHead",
                                @"blackThumbLeft",
                                @"thumbLeft",
                                @"blackDownThumb",
                                @"downThumb",
                                @"blackDoubleFistLight",
                                @"doubleFist",
                                @"blackLeftFist",
                                @"leftFist",
                                @"blackPointUp",
                                @"pointUp ",
                                @"blackPeaceHand",
                                @"peaceHand",
                                @"blackStrongArms",
                                @"strongArms",
                                @"blackRightThumb",
                                @"rightThumb",
                                @"blackAmbiguousHands",
                                @"ambiguousHands",
                                @"bigFist",
                                @"blackFist",
                                @"blackPalmsHands",
                                @"handsPalms",
                                @"blackClapHands",
                                @"clapHands",
                                @"bigPhone",
                                @"hammerThor",
                                @"umbrellaRain",
                                @"smallCamera ",
                                @"roseRed",
                                @"moneyUSA",
                                @"clapMarker",
                                @"knifeParty",
                                @"darkGun",
                                @"fireFire",
                                @"daBomb",
                                @"musicNotes",
                                @"dropBass",
                                @"sexySaxy",
                                @"donaldTrumpet",
                                @"playViola",
                                @"loudSpeaker",
                                @"questionMark",
                                @"exclamationPoint",
                                @"cartoonOuchie",
                                @"sleepZees",
                                @"lightBulb",
                                @"lollipop",
                                @"iceCream",
                                @"waterMelon",
                                @"coffeeMug",
                                @"babyBottle",
                                @"beerMug",
                                @"maitaiGlass",
                                @"martiniGlass",
                                @"wineGlass"];
        
        NSMutableArray *outputImages = [[NSMutableArray alloc] initWithCapacity:imageNames.count];
        
        for (NSString *name in imageNames) {
            MEOverlayImage *tmpImage = [[MEOverlayImage alloc] initWithImageName:name];
            [outputImages addObject:tmpImage];
        }
        
        allImages = [outputImages copy];
    });
    
    return allImages;
}

+ (NSArray *)hipHopPack
{
    static NSArray *allImages = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSArray *imageNames = @[
                                @"bandanaLowerFace",
                                @"roundedSunglasses",
                                @"champagne",
                                @"bucketHat",
                                @"styrofoamCupWithDrank",
                                @"grillBlack",
                                @"grillWhite",
                                @"redEyes",
                                @"dollarEyes",
                                @"iceCreamTattoo",
                                @"snapback",
                                @"doRag",
                                @"goldChain",
                                @"goldChain2",
                                @"joint",
                                @"blunt",
                                @"chalice",
                                @"goldMic",
                                @"headphones",
                                @"deuces",
                                @"deucesBlack",
                                @"middleFinger",
                                @"middleFingerBlack",
                                @"westside",
                                @"westsideBlack"
                                ];
        
        
        NSMutableArray *outputImages = [[NSMutableArray alloc] initWithCapacity:imageNames.count];
        
        for (NSString *name in imageNames) {
            MEOverlayImage *tmpImage = [[MEOverlayImage alloc] initWithImageName:name];
            [outputImages addObject:tmpImage];
        }
        
        allImages = [outputImages copy];
    });
    
    return allImages;
}

#pragma mark -
#pragma mark StoreKitShit
- (void)purchaseProduct:(SKProduct *)product withCompletion:(PurchaseCallback)callback;
{
    self.purchaseCompletion = callback;
    
    if (![SKPaymentQueue canMakePayments]) {
        
        NSLog(@"User can't make payments on this device, should be checking earlier in the callchain");
        self.purchaseCompletion(NO);
        return;
    }
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    [payment setQuantity:1];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    for (SKProduct *product in response.products) {
        if ([product.productIdentifier isEqualToString:hipHopPackProductIdentifier]) {
            self.hipHopPackProduct = product;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                // Do nothing???
                break;
            case SKPaymentTransactionStatePurchased:
                if ([transaction.payment.productIdentifier isEqualToString:hipHopPackProductIdentifier]) {
                    [self setHipHopPackEnabled:YES];
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                if (self.purchaseCompletion) {
                    self.purchaseCompletion(YES);
                }
                break;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                if (self.purchaseCompletion) {
                    self.purchaseCompletion(NO);
                }
                break;
            case SKPaymentTransactionStateRestored:
                
                if ([transaction.payment.productIdentifier isEqualToString:hipHopPackProductIdentifier]) {
                    [self setHipHopPackEnabled:YES];
                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                if (self.purchaseCompletion) {
                    self.purchaseCompletion(YES);
                }
                break;
            case SKPaymentTransactionStateDeferred:
                if (self.purchaseCompletion) {
                    NSLog(@"Needs parent's permission???"); //TODO : Implement this?
                    self.purchaseCompletion(NO);
                }
                break;
            default:
                break;
        }
    }
}

- (void)restorePurchasesCompletion:(PurchaseCallback)callback;
{
    self.restoreCompletion = callback;
    
    self.receiptRequest = [[SKReceiptRefreshRequest alloc] init];
    [self.receiptRequest setDelegate:self];
    [self.receiptRequest start];
}

- (void)requestDidFinish:(SKRequest *)request
{
    for (DHInAppReceipt *inAppReceipt in [[DHAppStoreReceipt mainBundleReceipt] inAppReceipts]) {
        if ([inAppReceipt.productId isEqualToString:hipHopPackProductIdentifier]) {
            [self setHipHopPackEnabled:YES];
        }
    }
    if (self.restoreCompletion) {
        self.restoreCompletion(YES);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if ([request isEqual:self.productRequest]) {
        [self.productRequest cancel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Request failed. Trying to fetch products again...");
            self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:hipHopPackProductIdentifier, nil]];
            [self.productRequest setDelegate:self];
            [self.productRequest start];
        });
    }
    if (self.restoreCompletion) {
        self.restoreCompletion(NO);
    }
}

- (BOOL)hipHopPackEnabled
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:hipHopPackProductIdentifier] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:hipHopPackProductIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:hipHopPackProductIdentifier];
}


- (void)setHipHopPackEnabled:(BOOL)hipHopPackEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:hipHopPackEnabled forKey:hipHopPackProductIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)watermarkEnabled;
{
    if ([[NSUserDefaults standardUserDefaults] objectForKey:watermarkProductIdentifier] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:watermarkProductIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:watermarkProductIdentifier];
}


- (void)setWatermarkEnabled:(BOOL)watermarkEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:watermarkEnabled forKey:watermarkProductIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
