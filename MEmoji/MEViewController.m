//
//  MEViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewController.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>
#import <UIView+Positioning.h>
#import <UIColor+Hex.h>
#import <JGProgressHUD.h>
#import <UIView+Shimmer.h>
#import <UIAlertView+Blocks.h>
#import "MEOverlayCell.h"
#import "MESectionHeaderReusableView.h"
#import "MECaptureButton.h"

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup
    [self.view setBackgroundColor:[MEModel mainColor]];
    self.viewFinder = [[MEViewFinder alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.width) previewLayer:[[MEModel sharedInstance] previewLayer]];
    [self.viewFinder setDelegate:self];
    [self.viewFinder.topRightButton setImage:[UIImage imageNamed:@"flipCamera"] forState:UIControlStateNormal];
    [self.viewFinder.bottomRightButton setImage:[UIImage imageNamed:@"toggleMask"] forState:UIControlStateNormal];
    [self.viewFinder.bottomLeftButton setImage:[UIImage imageNamed:@"recentButton"] forState:UIControlStateNormal];
    [self.viewFinder.topLeftButton setImage:[UIImage imageNamed:@"deleteXBlack"] forState:UIControlStateNormal];
    [self.view addSubview:self.viewFinder];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.viewFinder.bottom, self.view.width, self.view.height - self.viewFinder.height)];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.width*2, self.scrollView.height)];
    [self.scrollView setBackgroundColor:[MEModel mainColor]];
    [self.scrollView setDelegate:self];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setDirectionalLockEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.view insertSubview:self.scrollView belowSubview:self.viewFinder];
    
    // The controller to rule them all
    self.collectionViewController = [[MECollectionViewController alloc] init];
    [self.collectionViewController setDelegate:self];
    
    // Library Collection View
    self.libraryCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.width, self.scrollView.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.libraryCollectionView setDelegate:self.collectionViewController];
    [self.libraryCollectionView setDataSource:self.collectionViewController];
    [self.libraryCollectionView registerClass:[MEMEmojiCell class] forCellWithReuseIdentifier:@"MEmojiCell"];
    [self.libraryCollectionView registerClass:[MESectionHeaderReusableView class]
                   forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                          withReuseIdentifier:@"HeaderView"];
    [self.libraryCollectionView setAlwaysBounceVertical:YES];
    [self.libraryCollectionView setScrollsToTop:YES];
    [self.libraryCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.scrollView addSubview:self.libraryCollectionView];
    [self.collectionViewController setLibraryCollectionView:self.libraryCollectionView];
    
    self.standardCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.scrollView.width, 0, self.scrollView.width, self.scrollView.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.standardCollectionView setDelegate:self.collectionViewController];
    [self.standardCollectionView setDataSource:self.collectionViewController];
    [self.standardCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.standardCollectionView registerClass:[MESectionHeaderReusableView class]
                   forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                          withReuseIdentifier:@"HeaderView"];
    [self.standardCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.standardCollectionView setAlwaysBounceVertical:YES];
    [self.standardCollectionView setAllowsMultipleSelection:YES];
    [self.standardCollectionView setScrollsToTop:NO];
    [self.scrollView addSubview:self.standardCollectionView];
    [self.collectionViewController setStandardCollectionView:self.standardCollectionView];
    
    // Capture Button
    CGRect captureButtonFrame = CGRectMake(0, 0, captureButtonDiameter, captureButtonDiameter);
    self.captureButton = [[MECaptureButton alloc] initWithFrame:captureButtonFrame];
    [self.captureButton setCenter:CGPointMake(self.viewFinder.centerX, self.viewFinder.bottom)];
    self.captureButton.alpha = 0.90;
    [self.view addSubview:self.captureButton];

    // Gestures
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.captureButton addGestureRecognizer:singleTapRecognizer];
    UILongPressGestureRecognizer *longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.captureButton addGestureRecognizer:longPressRecognier];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.75 delay:0.75 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.scrollView setContentOffset:CGPointMake(self.scrollView.width, 0)];
    } completion:nil];

    [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:@"MainView"];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark -
#pragma mark MEViewFinderDelegate

- (void)viewFinder:(MEViewFinder *)viewFinder didTapButton:(UIButton *)button
{
    if ([button isEqual:self.viewFinder.topRightButton])
    {
        [[MEModel sharedInstance] toggleCameras];
    }else if ([button isEqual:self.viewFinder.bottomRightButton])
    {
        [self.viewFinder setShowingMask:!self.viewFinder.showingMask];
    }else if ([button isEqual:self.viewFinder.bottomLeftButton])
    {
        [self.libraryCollectionView setContentOffset:CGPointMake(0, 0) animated:(self.scrollView.contentOffset.x == 0)];
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.scrollView setContentOffset:CGPointMake(0, 0)];
        } completion:nil];
    }else if ([button isEqual:self.viewFinder.topLeftButton])
    {
        for (MEOverlayImage *overlayImage in [[MEModel sharedInstance] currentOverlays]) {
            [overlayImage.layer removeFromSuperlayer];
        }
        [[[MEModel sharedInstance] currentOverlays] removeAllObjects];
        [self.standardCollectionView reloadData];
    }
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
        [self.captureButton scaleUp];
        [self startRecording];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stepOfGIF/2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self finishRecording];
            [self.captureButton scaleDown];
            [self.captureButton startSpinning];
        });
    }
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
            [self.captureButton scaleUp];
            [self startRecording];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        [self finishRecording];
        [self.captureButton scaleDown];
        [self.captureButton startSpinning];
    }
}

#pragma mark -
#pragma mark AVCaptureMovieFileDelegate
- (void)startRecording
{
    NSString *path = [MEModel currentVideoPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error){ NSLog(@"Error: %@", error);}
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    [[[MEModel sharedInstance] fileOutput] startRecordingToOutputFileURL:url recordingDelegate:self];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    
}

- (void)finishRecording
{
    [[[MEModel sharedInstance] fileOutput] stopRecording];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (!error) {
        [self captureGIF];
        return;
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video could not be converted for some reason!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)captureGIF
{
    NSURL *url = [NSURL fileURLWithPath:[MEModel currentVideoPath]];
    NSMutableArray *overlaysToRender = [[NSMutableArray alloc] init];
    
    // Add mask first
    if (self.viewFinder.showingMask) {
        [overlaysToRender addObject:[UIImage imageNamed:@"maskLayer"]];
    }
    
    for (MEOverlayImage *overlayImage in [[MEModel sharedInstance] currentOverlays]) {
        [overlaysToRender addObject:overlayImage.image];
    }
    
    // Finally, add watermark layer
    if (YES) {
        [overlaysToRender addObject:[UIImage imageNamed:@"waterMark"]];
    }
    
    [[MEModel sharedInstance] createEmojiFromMovieURL:url andOverlays:[overlaysToRender copy] complete:^{
        [[MEModel sharedInstance] reloadCurrentImages];
        [self.libraryCollectionView reloadData];
        [self.captureButton stopSpinning];
        
        [self.collectionViewController collectionView:self.libraryCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

    }];
}

#pragma mark -
#pragma mark UIMessageComposeViewController Delegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark MECollectionViewControllerDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectOverlay:(MEOverlayImage *)overlay
{
    [[[MEModel sharedInstance] currentOverlays] addObject:overlay];
    [overlay.layer setFrame:self.viewFinder.bounds];
    [self.viewFinder.previewLayer addSublayer:overlay.layer];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselctOverlay:(MEOverlayImage *)overlay;
{
    [[[MEModel sharedInstance] currentOverlays] removeObject:overlay];
    [overlay.layer removeFromSuperlayer];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectImage:(Image *)image
{
    [self.viewFinder presentImage:image];
}

- (void)headerButtonWasTapped:(UIButton *)sender
{
    switch (sender.tag) {
        case MEHeaderButtonTypeLeftArrow: {
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self.scrollView setContentOffset:CGPointMake(MAX(0,self.scrollView.contentOffset.x - self.scrollView.width), 0)];
            } completion:nil];
            break;
        }
        case MEHeaderButtonTypeRightArrow:{
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self.scrollView setContentOffset:CGPointMake(MIN(self.scrollView.contentSize.width - self.scrollView.width, self.scrollView.contentOffset.x + self.scrollView.width), 0)];
            } completion:nil];
            break;
        }
        case MEHeaderButtonTypeDelete:
            [self.libraryCollectionView setAllowsMultipleSelection:!self.libraryCollectionView.allowsMultipleSelection];
            [self.libraryCollectionView reloadData];
            break;
            
        case MEHeaderButtonTypePurchase:
            NSLog(@"Purchase button pressed.");
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark MEShareViewDelegate
- (void)shareview:(MEShareView *)shareView didSelectOption:(MEShareOption)option
{
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
    
    switch (option) {
        case MEShareOptionFacebook: {
            // Do nothing currently
            break;
        }
        case MEShareOptionNone: {
            [self dismissShareView];
            break;
        }
        case MEShareOptionSaveToLibrary: {
            [UIAlertView showWithTitle:@"Save to Library"
                               message:@"Select how you would like to\nsave your MEmoji."
                     cancelButtonTitle:@"Cancel"
                     otherButtonTitles:@[@"Save as GIF", @"Save as Video"]
                              tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                  
                                  [self dismissShareView];
                                  if (buttonIndex > 0) {
                                      
                                      [HUD showInView:self.view animated:YES];
                                      
                                      if (buttonIndex == 1) { // Save as GIF
                                          
                                          ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                                          [library writeImageDataToSavedPhotosAlbum:[[[MEModel sharedInstance] selectedImage] imageData]
                                                                           metadata:nil
                                                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                                                        [HUD dismissAnimated:YES];
                                                                    }];
                                          
                                      }else if (buttonIndex == 2){ // Save as Video
                                          
                                          NSURL *whereToWrite = [NSURL fileURLWithPath:[MEModel currentVideoPath]];
                                          NSError *error;
                                          if ([[NSFileManager defaultManager] fileExistsAtPath:[MEModel currentVideoPath]]) {
                                              [[NSFileManager defaultManager] removeItemAtURL:whereToWrite error:&error];
                                              if (error) {
                                                  NSLog(@"An Error occured writing to file. %@", error.debugDescription);
                                              }
                                          }
                                          
                                          [[[[MEModel sharedInstance] selectedImage] movieData] writeToURL:[NSURL fileURLWithPath:[MEModel currentVideoPath]] atomically:YES];
                                          
                                          ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                                          [library writeVideoAtPathToSavedPhotosAlbum:whereToWrite completionBlock:^(NSURL *assetURL, NSError *error) {
                                              if (error) {
                                                  NSLog(@"Error saving asset to camera. %@", error.debugDescription);
                                              }
                                              [HUD dismissAnimated:YES];
                                              // TODO : Confirm saved as Video
                                          }];
                                      }
                                  }
                              }];
            break;
        }
        case MEShareOptionMessages: {
            [self dismissShareView];
            [HUD showInView:self.view animated:YES];
            self.messageController = [[MFMessageComposeViewController alloc] init];
            [self.messageController setMessageComposeDelegate:self];
            [self.messageController addAttachmentData:[[[MEModel sharedInstance] selectedImage] imageData]
                                       typeIdentifier:@"com.compuserve.gif"
                                             filename:[NSString stringWithFormat:@"MEmoji-%@.gif", [[[[MEModel sharedInstance] selectedImage] createdAt] description]]];
            
            [self presentViewController:self.messageController animated:YES completion:^{
                [HUD dismissAnimated:YES];
            }];
            break;
        }
        case MEShareOptionInstagram: {
            [self dismissShareView];
            [HUD showInView:self.view animated:YES];
            
            NSURL *whereToWrite = [NSURL fileURLWithPath:[MEModel currentVideoPath]];
            NSError *error;
            if ([[NSFileManager defaultManager] fileExistsAtPath:[MEModel currentVideoPath]]) {
                [[NSFileManager defaultManager] removeItemAtURL:whereToWrite error:&error];
                if (error) {
                    NSLog(@"An Error occured writing to file. %@", error.debugDescription);
                }
            }
            
            [[[[MEModel sharedInstance] selectedImage] movieData] writeToURL:[NSURL fileURLWithPath:[MEModel currentVideoPath]] atomically:YES];
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:whereToWrite completionBlock:^(NSURL *assetURL, NSError *error) {
                if (error) {
                    NSLog(@"Error saving asset to camera. %@", error.debugDescription);
                }
                [HUD dismissAnimated:YES];
                [UIAlertView showWithTitle:@"Saved Video to Library"
                                   message:@"You can post your MEmoji by selecting it from your library once in Instagram."
                         cancelButtonTitle:@"Let's go!"
                         otherButtonTitles:nil
                                  tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                      NSURL *instagramURL = [NSURL URLWithString:@"instagram://camera"];
                                      if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
                                          [[UIApplication sharedApplication] openURL:instagramURL];
                                      }
                                  }];
            }];
            break;
        }
        case MEShareOptionTwitter: {
            [self dismissShareView];
            [HUD showInView:self.view animated:YES];
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeImageDataToSavedPhotosAlbum:[[[MEModel sharedInstance] selectedImage] imageData]
                                             metadata:nil
                                      completionBlock:^(NSURL *assetURL, NSError *error) {
                                          [HUD dismissAnimated:YES];
                                          
                                          [UIAlertView showWithTitle:@"Saved GIF to Library"
                                                             message:@"You can tweet your MEmoji by selecting it from your library once in Twitter."
                                                   cancelButtonTitle:@"Let's go!"
                                                   otherButtonTitles:nil
                                                            tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                                
                                                                NSString *stringURL = @"twitter://post";
                                                                NSURL *url = [NSURL URLWithString:stringURL];
                                                                [[UIApplication sharedApplication] openURL:url];
                                                            }];
                                      }];
            break;
        }
        default:
            break;
    }
}

- (void)presentShareView
{
    if (!self.shareView) {
        self.shareView = [[MEShareView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.width, self.scrollView.height)];
        [self.shareView setDelegate:self];
        [self.shareView setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.9]];
        [self.shareView setBottom:self.viewFinder.bottom];
        [self.view insertSubview:self.shareView belowSubview:self.viewFinder];
    }
    
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.shareView setAlpha:1];
        [self.shareView setY:self.viewFinder.bottom];
    } completion:nil];
}

- (void)dismissShareView
{
    [self.viewFinder dismissImage];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.shareView setBottom:self.viewFinder.bottom];
        [self.shareView setAlpha:0];
    } completion:nil];
}

#pragma mark -
#pragma mark Other Delegate methods
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        for (MEOverlayImage *overlayImage in [[MEModel sharedInstance] currentOverlays]) {
            [overlayImage.layer removeFromSuperlayer];
        }
        
        [[[MEModel sharedInstance] currentOverlays] removeAllObjects];
        [self.standardCollectionView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [[self.collectionViewController imageCache] removeAllObjects];
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end

