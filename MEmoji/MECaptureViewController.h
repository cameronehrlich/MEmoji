//
//  MECaptureViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 8/13/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <MBProgressHUD.h>
#import <UIView+Positioning.h>
#import <UIColor+Hex.h>

@import AVFoundation;

@interface MECaptureViewController : UIViewController <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognier;

@end
