//
//  MEViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//
#import <UIView+Positioning.h>
#import <LLARingSpinnerView.h>
#import <FSOpenInInstagram.h>

#import "MEMEmojiCell.h"
#import "MESectionsManager.h"
#import "MECaptureButton.h"
#import "MEShareView.h"
#import "MEViewFinder.h"
#import "MEIntroductionView.h"
#import "MESectionHeaderView.h"

@import MessageUI;
@import MobileCoreServices;
@import AssetsLibrary;

@interface MEViewController : UIViewController <UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate, MESectionsManagerDelegate, MEShareViewDelegate, MEViewFinderDelegate, MEIntroductionViewDelegate, MESectionHeaderViewDelegate>

@property (strong, nonatomic) MEViewFinder *viewFinder;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) MECaptureButton *captureButton;
@property (strong, nonatomic) MEIntroductionView *introductionView;

@property (strong, nonatomic) MESectionsManager *sectionsManager;

@property (strong, nonatomic) UIButton *maskToggleButton;
@property (strong, nonatomic) UIButton *flipCameraButton;
@property (strong, nonatomic) UIButton *smileyFaceButton;

@property (strong, nonatomic) MEShareView *shareView;
@property (strong, nonatomic) FSOpenInInstagram *instagramOpener;

@property (strong, nonatomic) MFMessageComposeViewController *messageController;
@property (strong, nonatomic) UILabel *instructionsLabel;

@end
