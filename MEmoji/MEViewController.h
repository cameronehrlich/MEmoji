//
//  MEViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//
#import <UIView+Positioning.h>
#import <LLARingSpinnerView.h>
#import "MEMEmojiCell.h"
#import "MECollectionViewController.h"
#import "MECaptureButton.h"
#import "MEShareView.h"
#import "MEViewFinder.h"

@import MessageUI;
@import MobileCoreServices;
@import AssetsLibrary;

@interface MEViewController : UIViewController <UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate, MECollectionViewControllerDelegate, MEShareViewDelegate, MEViewFinderDelegate>

@property (strong, nonatomic) MEViewFinder *viewFinder;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) MECollectionViewController *collectionViewController;
@property (strong, nonatomic) UICollectionView *libraryCollectionView;
@property (strong, nonatomic) UICollectionView *standardCollectionView;
@property (strong, nonatomic) MECaptureButton *captureButton;

@property (strong, nonatomic) UIButton *maskToggleButton;
@property (strong, nonatomic) UIButton *flipCameraButton;
@property (strong, nonatomic) UIButton *smileyFaceButton;

@property (strong, nonatomic) MEShareView *shareView;

@property (strong, nonatomic) MFMessageComposeViewController *messageController;

@property (assign, nonatomic) BOOL maskEnabled;

@end
