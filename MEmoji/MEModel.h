//
//  MEModel.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#define MR_LOGGING_ENABLED 0
#define MR_ENABLE_ACTIVE_RECORD_LOGGING 0

@import MagicalRecord;
@import UIImage_Additions;
@import JGProgressHUD;
@import Appirater;

#import <GAI.h>
#import <GAIFields.h>
#import <GAIDictionaryBuilder.h>
#import <DHAppleReceiptParser/DHAppStoreReceipt.h>

#import "CEMovieMaker.h"
#import "Image.h"
#import "MEOverlayImage.h"
#import "UIColor+Hex.h"

@import AVFoundation;
@import MediaPlayer;
@import AssetsLibrary;
@import ImageIO;
@import MessageUI;
@import MobileCoreServices;
@import StoreKit;

typedef void (^CreationCallback)();
typedef void (^PurchaseCallback)(BOOL success);
typedef void (^SaveCallback)(BOOL success);

typedef NS_ENUM(NSUInteger, MEHeaderButtonType) {
    MEHeaderButtonTypeRightArrow,
    MEHeaderButtonTypeLeftArrow,
    MEHeaderButtonTypeDelete,
    MEHeaderButtonTypePurchaseHipHopPack,
    MEHeaderButtonTypePurchaseHolidayPack,
};

typedef NS_ENUM(NSInteger, MEShareOption) {
    MEShareOptionSaveToLibrary,
    MEShareOptionInstagram,
    MEShareOptionTwitter,
    MEShareOptionMessages,
    MEShareOptionNone
};

typedef NS_ENUM(NSUInteger, MESettingsOption) {
    MESettingsOptionWatermark,
    MESettingsOptionRestore,
    MESettingsOptionReview,
    MESettingsOptionContact,
    MESettingsOptionIntroduction,
    MESettingsOptionNumberOfTypes, // Should be the total number of types
};

static const CGFloat dimensionOfGIF               = 320;
static const CGFloat stepOfGIF                    = 0.12;
static const CGFloat lengthOfGIF                  = 5;
static const NSInteger numberOfGIFVideoLoops      = 10;
static const NSInteger numberToLoadIncrementValue = 8;
static const NSInteger numberOfGIFsToKeep         = 32;

static NSString *hipHopPackProductIdentifier = @"hiphoppack";
static NSString *holidayPackProductIdentifier = @"holidaypack";
static NSString *watermarkProductIdentifier = @"watermark";

static NSString *reloadPurchaseableContentKey = @"reloadPurchaseableSections";
static NSString *firstRunKey = @"firstRunKey";

@interface MEModel : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureMovieFileOutput *videoFileOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, assign) BOOL capturingStill;
@property (nonatomic, strong) CEMovieMaker *movieMaker;
@property (copy)              SaveCallback saveCompletion;

@property (nonatomic, assign) NSInteger numberToLoad;
@property (nonatomic, strong) NSArray *currentImages;
@property (nonatomic, strong) NSMutableArray *currentOverlays;
@property (nonatomic, strong) Image *selectedImage;
@property (copy)              CreationCallback creationCompletion;

@property (nonatomic, strong) SKProduct *hipHopPackProduct;
@property (nonatomic, strong) SKProduct *holidayPackProduct;
@property (nonatomic, strong) SKProduct *watermarkProduct;
@property (nonatomic, assign) BOOL hipHopPackEnabled;
@property (nonatomic, assign) BOOL holidayPackEnabled;
@property (nonatomic, assign) BOOL watermarkEnabled;

@property (nonatomic, strong) SKProductsRequest *productRequest;
@property (nonatomic, strong) SKReceiptRefreshRequest *receiptRequest;
@property (copy)              PurchaseCallback purchaseCompletion;
@property (copy)              PurchaseCallback restoreCompletion;


@property (nonatomic, strong) JGProgressHUD *HUD;

- (void)purchaseProduct:(SKProduct *)product withCompletion:(PurchaseCallback)callback;
- (void)restorePurchasesCompletion:(PurchaseCallback)callback;
- (void)initializeCaptureSession;

+ (instancetype)sharedInstance;
+ (NSString *)currentVideoPath;

- (void)createImageAnimated:(BOOL)animated withOverlays:(NSArray *)overlays complete:(CreationCallback)callback;
- (void)saveMovieFromImage:(Image *)image withCompletion:(SaveCallback)completion;

- (NSData *)createGIFwithFrames:(NSArray *)images;
- (void)toggleCameras;
- (void)reloadCurrentImages;

+ (NSArray *)freePack;
+ (NSArray *)hipHopPack;
+ (NSArray *)holidayPack;

+ (UIColor *)mainColor;
+ (UIFont *)mainFontWithSize:(NSInteger)size;
+ (NSString *)formattedPriceForProduct:(SKProduct *)product;

@end
