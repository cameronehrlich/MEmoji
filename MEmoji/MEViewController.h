//
//  MEViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//
#import <UIView+Positioning.h>
#import "MEMEmojiCell.h"
#import "AWCollectionViewDialLayout.h"
#import <PulsingHaloLayer.h>

@import MessageUI;
@import MobileCoreServices;

@interface MEViewController : UIViewController <UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) CALayer *maskingLayer;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognier;

@property (strong, nonatomic) UIView *viewFinder;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UICollectionView *overlayCollectionView;
@property (strong, nonatomic) UIView *captureButtonView;

@property (strong, nonatomic) UICollectionView *libraryCollectionView;
@property (strong, nonatomic) AWCollectionViewDialLayout *layout;

@property (strong, nonatomic) MFMessageComposeViewController *messageController;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (assign, nonatomic) BOOL editing;

@property (strong, nonatomic) NSMutableArray *currentImages;
@property (strong, nonatomic) NSMutableDictionary *currentOverlays;
@property (strong, nonatomic) NSMutableDictionary *imageCache;

- (IBAction)editToggle:(id)sender;
- (IBAction)showOverlaysAction:(id)sender;

@end
