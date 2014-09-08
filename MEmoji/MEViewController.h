//
//  MEViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//
#import <UIView+Positioning.h>
#import "MEMEmojiCell.h"
#import "MEFlowLayout.h"
#import "ASHSpringyCollectionViewFlowLayout.h"
#import "AWCollectionViewDialLayout.h"
#import <PulsingHaloLayer.h>
#import <DACircularProgressView.h>

@import MessageUI;
@import MobileCoreServices;

@interface MEViewController : UIViewController <UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) DACircularProgressView *progressView;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognier;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) AWCollectionViewDialLayout *layout;

@property (strong, nonatomic) MFMessageComposeViewController *messageController;
@property (assign, nonatomic) BOOL inPullMode;

@property (strong, nonatomic) UIView *header;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (assign, nonatomic) BOOL editing;

@property (strong, nonatomic) NSMutableArray *currentImages;
@property (strong, nonatomic) NSMutableDictionary *imageCache;

- (IBAction)editToggle:(id)sender;

@end
