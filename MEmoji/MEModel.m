//
//  MEModel.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEModel.h"

static NSString *hipHopPackProductIdentifier = @"hiphoppack";

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
        
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        self.currentOverlays = [[NSMutableArray alloc] init];
        
        self.movieRenderingQueue = [[NSOperationQueue alloc] init];
        [self.movieRenderingQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
        
        [self initializeCaptureSession];
        
        self.productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects:hipHopPackProductIdentifier, nil]];
        [self.productRequest setDelegate:self];
        [self.productRequest start];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        self.HUD = [[JGProgressHUD alloc] initWithStyle:JGProgressHUDStyleLight];
    }
    return self;
}

- (void)reloadCurrentImages
{
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
}

- (void)createEmojiFromMovieURL:(NSURL *)url andOverlays:(NSArray *)overlays complete:(MEmojiCallback)callback
{
    self.creationCompletion = callback;
    
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
        Image *newImage = [Image MR_createEntityInContext:localContext];
        [newImage setCreatedAt:[NSDate date]];
        [newImage setImageData:GIFData];
        justSaved = newImage;

    } completion:^(BOOL success, NSError *error) {
        self.selectedImage = justSaved;
        self.creationCompletion();
        
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
    
    UIGraphicsBeginImageContextWithOptions(imgFrame.size, YES, 1);
    
    [imgFrame drawInRect:CGRectMake( 0, 0, dimensionOfGIF, dimensionOfGIF)];
    
    for (UIImage *overlay in overlays) {
        [overlay drawInRect:CGRectMake( 0, 0, dimensionOfGIF, dimensionOfGIF)];
    }
    
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

+ (NSArray *)standardPack
{
    static NSArray *allImages = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        NSArray *imageNames = @[
                                @"smallTears.png",
                                @"goldCrown.png",
                                @"kittyWhiskers.png",
                                @"nerdGlasses.png",
                                @"itsDoodoo.png",
                                @"prayingHands.png",
                                @"blackPrayingHands.png",
                                @"eyes.png",
                                @"creepyEyes.png",
                                @"stonerEyes.png",
                                @"blackEyes.png",
                                @"sunGlasses.png",
                                @"heartEyes.png",
                                @"heartArrow.png",
                                @"heartBroke.png",
                                @"cheekKiss.png",
                                @"sexyLips.png",
                                @"gritTeeth.png",
                                @"nostrilSmoke.png",
                                @"tongueLaugh.png",
                                @"bigLaugh.jpg",
                                @"oneTear.png",
                                @"bigTears.png",
                                @"waterfallTears.png",
                                @"monkeySpeak.png",
                                @"pigNose.png",
                                @"santaHatBeard.png",
                                @"toiletFace.png",
                                @"afroHair.png",
                                @"flatTop.png",
                                @"mohawkBlack.png",
                                @"mohawkBlonde.png",
                                @"mustacheNewerThinnerVersion.png",
                                @"oldTimeyMustache.png",
                                @"blueHalo.png",
                                @"pinkBow.png",
                                @"topHat.png",
                                @"turbanAllah.png",
                                @"graduationCap.png",
                                @"policeHat.png",
                                @"russianHat.png",
                                @"chinaHat.png",
                                @"surgicalMask.png",
                                @"fmlForehead.png",
                                @"halfCigarette.png",
                                @"showerHead.png",
                                @"blackThumbLeft.png",
                                @"thumbLeft.png",
                                @"blackDownThumb.png",
                                @"downThumb.png",
                                @"blackDoubleFistLight.png",
                                @"doubleFist.png",
                                @"blackLeftFist.png",
                                @"leftFist.png",
                                @"blackPointUp.png",
                                @"pointUp.png ",
                                @"blackPeaceHand.png ",
                                @"peaceHand.png ",
                                @"blackStrongArms.png ",
                                @"strongArms.png",
                                @"blackRightThumb.png",
                                @"rightThumb.png",
                                @"blackAmbiguousHands.png",
                                @"ambiguousHands.png",
                                @"bigFist.png",
                                @"blackFist.png",
                                @"blackPalmsHands.png",
                                @"handsPalms.png",
                                @"blackClapHands.png",
                                @"clapHands.png",
                                @"bigPhone.png",
                                @"hammerThor.png",
                                @"umbrellaRain.png",
                                @"smallCamera.png ",
                                @"roseRed.png",
                                @"moneyUSA.png",
                                @"clapMarker.png",
                                @"knifeParty.png",
                                @"darkGun.png",
                                @"fireFire.png",
                                @"daBomb.png",
                                @"musicNotes.png",
                                @"dropBass.png",
                                @"sexySaxy.png",
                                @"donaldTrumpet.png",
                                @"playViola.png",
                                @"loudSpeaker.png",
                                @"questionMark.png",
                                @"exclamationPoint.png",
                                @"cartoonOuchie.png",
                                @"sleepZees.png",
                                @"lightBulb.png",
                                @"lollipop.png",
                                @"iceCream.png",
                                @"waterMelon.png",
                                @"coffeeMug.png",
                                @"babyBottle.png",
                                @"beerMug.png",
                                @"maitaiGlass.png",
                                @"martiniGlass.png",
                                @"wineGlass.png"];
        
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
                                @"bandanaLowerFace.png",
                                @"roundedSunglasses.png",
                                @"champagne.png",
                                @"bucketHat.png",
                                @"styrofoamCupWithDrank.png",
                                @"grillBlack.png",
                                @"grillWhite.png",
                                @"redEyes.png",
                                @"dollarEyes.png",
                                @"iceCreamTattoo.png",
                                @"snapback.png",
                                @"doRag.png",
                                @"goldChain.png",
                                @"goldChain2.png",
                                @"joint.png",
                                @"blunt.png",
                                @"chalice.png",
                                @"goldMic.png",
                                @"headphones.png",
                                @"deuces.png",
                                @"deucesBlack.png",
                                @"middleFinger.png",
                                @"middleFingerBlack.png",
                                @"westside.png",
                                @"westsideBlack.png"
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
    NSLog(@"Failed in %s with error: %@", __PRETTY_FUNCTION__, error.debugDescription);
    if ([request isEqual:self.productRequest]) {
        [self.productRequest cancel];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Trying to fetch products again...");
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

@end
