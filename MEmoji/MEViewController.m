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
#import <UIView+Shimmer.h>
#import <UIAlertView+Blocks.h>
#import <ReactiveCocoa.h>
#import "MEOverlayCell.h"
#import "MESectionHeaderView.h"
#import "MECaptureButton.h"

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup
    self.viewFinder = [[MEViewFinder alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.width) previewLayer:[[MEModel sharedInstance] previewLayer]];
    [self.viewFinder setDelegate:self];
    [self.viewFinder.topRightButton setImage:[UIImage imageNamed:@"flipCamera"] forState:UIControlStateNormal];
    [self.viewFinder.bottomRightButton setImage:[UIImage imageNamed:@"deleteXBlack"] forState:UIControlStateNormal];
    [self.viewFinder.bottomLeftButton setImage:[UIImage imageNamed:@"recentButton"] forState:UIControlStateNormal];
    [self.viewFinder.topLeftButton setImage:[UIImage imageNamed:@"toggleMask"] forState:UIControlStateNormal];
    [self.view addSubview:self.viewFinder];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.viewFinder.bottom, self.view.width, self.view.height - self.viewFinder.height)];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.width*3, self.scrollView.height)];
    [self.scrollView setBackgroundColor:[UIColor lightGrayColor]];
    [self.scrollView setDelegate:self];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setDirectionalLockEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.view insertSubview:self.scrollView belowSubview:self.viewFinder];
    
    // Instruction Label
    self.instructionsLabel = [[UILabel alloc] initWithFrame:self.scrollView.bounds];
    [self.instructionsLabel setFont:[MEModel mainFontWithSize:25]];
    [self.instructionsLabel setTextAlignment:NSTextAlignmentCenter];
    [self.instructionsLabel setTextColor:[UIColor lightTextColor]];
    [self.instructionsLabel setAdjustsFontSizeToFitWidth:YES];
    [self.instructionsLabel setText:@"Tap button for still,\nhold for GIF."];
    [self.instructionsLabel setNumberOfLines:2];
    [self.instructionsLabel startShimmering];
    [self.scrollView addSubview:self.instructionsLabel];
    
    [RACObserve([MEModel sharedInstance], currentImages) subscribeNext:^(id x) {
        if ([[[MEModel sharedInstance] currentImages] count] == 0) {
            [self.instructionsLabel startShimmering];
            [self.instructionsLabel setHidden:NO];
        }else{
            [self.instructionsLabel stopShimmering];
            [self.instructionsLabel setHidden:YES];
        }
    }];
    
    // One controller to rule them all
    self.sectionsManager = [[MESectionsManager alloc] init];
    [self.sectionsManager setDelegate:self];
    
    // Library Collection View
    self.sectionsManager.libraryCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.scrollView.width * 0, 0, self.scrollView.width, self.scrollView.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.sectionsManager.libraryCollectionView setDelegate:self.sectionsManager];
    [self.sectionsManager.libraryCollectionView setDataSource:self.sectionsManager];
    [self.sectionsManager.libraryCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.sectionsManager.libraryCollectionView registerClass:[MEMEmojiCell class] forCellWithReuseIdentifier:@"MEmojiCell"];
    [self.sectionsManager.libraryCollectionView setAlwaysBounceVertical:YES];
    [self.sectionsManager.libraryCollectionView setScrollsToTop:YES];
    [self.scrollView addSubview:self.sectionsManager.libraryCollectionView];
    
    MESectionHeaderView *libraryHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width * 0, 0, self.scrollView.width, captureButtonDiameter/2)];
    [libraryHeader.leftButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    [libraryHeader.leftButton setTransform:CGAffineTransformMakeScale(0.9, 0.9)];
    [libraryHeader.leftButton setTag:MEHeaderButtonTypeDelete];
    [libraryHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [libraryHeader.titleImage setImage:[UIImage imageNamed:@"myMemojiLabel"]] ; // TODO : SWAP OUT
    [libraryHeader.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
    [libraryHeader.rightButton setTag:MEHeaderButtonTypeRightArrow];
    [libraryHeader.rightButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:libraryHeader];

    // Free Pack
    self.sectionsManager.freeCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.scrollView.width * 1, 0, self.scrollView.width, self.scrollView.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.sectionsManager.freeCollectionView setDelegate:self.sectionsManager];
    [self.sectionsManager.freeCollectionView setDataSource:self.sectionsManager];
    [self.sectionsManager.freeCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.sectionsManager.freeCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.sectionsManager.freeCollectionView setAlwaysBounceVertical:YES];
    [self.sectionsManager.freeCollectionView setAllowsMultipleSelection:YES];
    [self.sectionsManager.freeCollectionView setScrollsToTop:NO];
    [self.scrollView addSubview:self.sectionsManager.freeCollectionView];
    
    MESectionHeaderView *freePackHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width * 1, 0, self.scrollView.width, captureButtonDiameter/2)];
    [freePackHeader.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
    [freePackHeader.leftButton setTag:MEHeaderButtonTypeLeftArrow];
    [freePackHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [freePackHeader.titleImage setImage:[UIImage imageNamed:@"freePackLabel"]];
    [freePackHeader.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
    [freePackHeader.rightButton setTag:MEHeaderButtonTypeRightArrow];
    [freePackHeader.rightButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:freePackHeader];
    
    // Hip-Hop Pack
    self.sectionsManager.hipHopCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.scrollView.width * 2, 0, self.scrollView.width, self.scrollView.height)
                                                     collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.sectionsManager.hipHopCollectionView setDelegate:self.sectionsManager];
    [self.sectionsManager.hipHopCollectionView setDataSource:self.sectionsManager];
    [self.sectionsManager.hipHopCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.sectionsManager.hipHopCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.sectionsManager.hipHopCollectionView setAlwaysBounceVertical:YES];
    [self.sectionsManager.hipHopCollectionView setAllowsMultipleSelection:YES];
    [self.sectionsManager.hipHopCollectionView setScrollsToTop:NO];
    [self.scrollView addSubview:self.sectionsManager.hipHopCollectionView];
    
    MESectionHeaderView *hipHopPackHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width * 2, 0, self.scrollView.width, captureButtonDiameter/2)];
    [hipHopPackHeader.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
    [hipHopPackHeader.leftButton setTag:MEHeaderButtonTypeLeftArrow];
    [hipHopPackHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [hipHopPackHeader.titleImage setImage:[UIImage imageNamed:@"hiphopPackLabel"]];

    [hipHopPackHeader.purchaseButton setTag:MEHeaderButtonTypePurchaseHipHopPack];
    [hipHopPackHeader.purchaseButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:hipHopPackHeader];
    
    if ([[MEModel sharedInstance] hipHopPackEnabled]) {
        [self.sectionsManager.hipHopCollectionView setAlpha:1];
    }else{
        [self.sectionsManager.hipHopCollectionView setAlpha:0.4];
        [RACObserve([MEModel sharedInstance], hipHopPackProduct) subscribeNext:^(id x) {
            if (x) {
                NSString *priceString = [MEModel formattedPriceForProduct:x];
                [hipHopPackHeader.purchaseButton setTitle:[NSString stringWithFormat:@"Buy %@", priceString] forState:UIControlStateNormal];
                [hipHopPackHeader.purchaseButton setUserInteractionEnabled:YES];
            }else{
                [hipHopPackHeader.purchaseButton setTitle:[NSString stringWithFormat:@"Buy"] forState:UIControlStateNormal];
                [hipHopPackHeader.purchaseButton setUserInteractionEnabled:NO];
            }
        }];
    }
    
    // Capture Button
    CGRect captureButtonFrame = CGRectMake(0, 0, captureButtonDiameter, captureButtonDiameter);
    self.captureButton = [[MECaptureButton alloc] initWithFrame:captureButtonFrame];
    [self.captureButton setCenter:CGPointMake(self.viewFinder.centerX, self.viewFinder.bottom)];
    [self.view addSubview:self.captureButton];

    // Gestures
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.captureButton addGestureRecognizer:singleTapRecognizer];
    UILongPressGestureRecognizer *longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [longPressRecognier setMinimumPressDuration:0.15];
    [self.captureButton addGestureRecognizer:longPressRecognier];
    
    [self updateViewFinderButtons];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:@"MainView"];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createAppView] build]];
    
    if ([[[MEModel sharedInstance] currentImages] count] != 0) {
        
        [UIView animateWithDuration:0.75 delay:0.3 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.width, 0)];
        } completion:nil];
    }
}

- (void)clearInterface
{
    for (MEOverlayImage *overlayImage in [[MEModel sharedInstance] currentOverlays]) {
        [overlayImage.layer removeFromSuperlayer];
    }
    
    [[[MEModel sharedInstance] currentOverlays] removeAllObjects];
    [self.sectionsManager.freeCollectionView reloadData];
    [self.sectionsManager.hipHopCollectionView reloadData];
    
    [self updateViewFinderButtons];
}

- (void)updateViewFinderButtons
{
    [UIView animateWithDuration:0.2 animations:^{
        if ([[[MEModel sharedInstance] currentOverlays] count] > 0) {
            [self.viewFinder.bottomRightButton setUserInteractionEnabled:YES];
            [self.viewFinder.bottomRightButton setAlpha:1];
        }else{
            [self.viewFinder.bottomRightButton setUserInteractionEnabled:NO];
            [self.viewFinder.bottomRightButton setAlpha:0];
        }
    }];
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
        [self clearInterface];
    }else if ([button isEqual:self.viewFinder.bottomLeftButton])
    {
        [self.sectionsManager.libraryCollectionView setContentOffset:CGPointMake(0, 0) animated:(self.scrollView.contentOffset.x == 0)];
        
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.scrollView setContentOffset:CGPointMake(0, 0)];
        } completion:nil];
    }else if ([button isEqual:self.viewFinder.topLeftButton])
    {
        [self.viewFinder setShowingMask:!self.viewFinder.showingMask];
    }
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
        [self.captureButton scaleUp];
        [self startRecording];
        [self finishRecording];
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
    else if (sender.state == UIGestureRecognizerStateEnded ||
             sender.state == UIGestureRecognizerStateCancelled ||
             sender.state == UIGestureRecognizerStateFailed) {
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

- (void)finishRecording // Be careful not to call this without calling startRecording beforehand
{
    if ([[MEModel sharedInstance] fileOutput].isRecording) {
        [self.captureButton scaleDown];
        [self.captureButton startSpinning];
        [[[MEModel sharedInstance] fileOutput] stopRecording];
    }else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stepOfGIF/2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self finishRecording];
        });
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (!error) {
        [self captureGIF];
        return;
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video could not be converted for some reason!\nTry again!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)captureGIF
{
    [self.sectionsManager.libraryCollectionView setAllowsMultipleSelection:NO];
    [self.sectionsManager.libraryCollectionView reloadData];
    
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
        [self.sectionsManager.libraryCollectionView reloadData];
        [self.captureButton stopSpinning];
        [self.sectionsManager collectionView:self.sectionsManager.libraryCollectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
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
    
    [self updateViewFinderButtons];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselctOverlay:(MEOverlayImage *)overlay;
{
    [[[MEModel sharedInstance] currentOverlays] removeObject:overlay];
    [overlay.layer removeFromSuperlayer];
    
    [self updateViewFinderButtons];
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
            [self.sectionsManager.libraryCollectionView setAllowsMultipleSelection:!self.sectionsManager.libraryCollectionView.allowsMultipleSelection];
            [self.sectionsManager.libraryCollectionView reloadData];
            break;
            
        case MEHeaderButtonTypePurchaseHipHopPack:
        {
            if (![SKPaymentQueue canMakePayments]) {
                [[[UIAlertView alloc] initWithTitle:@"In-App Purchases Disabled"
                                            message:@"It appears that this device is not able to make In-App purchases, perhaps check your parental controls?"
                                           delegate:nil
                                  cancelButtonTitle:@"Okay"
                                  otherButtonTitles:nil] show];
                 return;
            }
            if (![[MEModel sharedInstance] hipHopPackProduct]) {
                [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                            message:@"It appears there was an error, check your internet connection?"
                                           delegate:nil
                                  cancelButtonTitle:@"Okay"
                                  otherButtonTitles:nil] show];
            }

            [[MEModel sharedInstance].HUD showInView:self.view];
            [[MEModel sharedInstance] purchaseProduct:[[MEModel sharedInstance] hipHopPackProduct] withCompletion:^(BOOL success) {
                [[MEModel sharedInstance].HUD dismiss];
                if (success) {
                    [self.sectionsManager.hipHopCollectionView reloadData];
                    NSLog(@"Unlocked Hip-Hop Pack");
                }
            }];
            break;
        }
        default:
            break;
    }
}

#pragma mark -
#pragma mark MEShareViewDelegate
- (void)shareview:(MEShareView *)shareView didSelectOption:(MEShareOption)option
{
    [MEModel sharedInstance].HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
    
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
                                      
                                      [[MEModel sharedInstance].HUD showInView:self.view animated:YES];
                                      
                                      if (buttonIndex == 1) { // Save as GIF
                                          
                                          ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                                          [library writeImageDataToSavedPhotosAlbum:[[[MEModel sharedInstance] selectedImage] imageData]
                                                                           metadata:nil
                                                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                                                        [[MEModel sharedInstance].HUD dismissAnimated:YES];
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
                                              [[MEModel sharedInstance].HUD dismissAnimated:YES];
                                              // TODO : Confirm saved as Video
                                          }];
                                      }
                                  }
                              }];
            break;
        }
        case MEShareOptionMessages: {
            [self dismissShareView];
            [[MEModel sharedInstance].HUD showInView:self.view animated:YES];
            self.messageController = [[MFMessageComposeViewController alloc] init];
            [self.messageController setMessageComposeDelegate:self];
            [self.messageController addAttachmentData:[[[MEModel sharedInstance] selectedImage] imageData]
                                       typeIdentifier:@"com.compuserve.gif"
                                             filename:[NSString stringWithFormat:@"MEmoji-%@.gif", [[[[MEModel sharedInstance] selectedImage] createdAt] description]]];
            
            [self presentViewController:self.messageController animated:YES completion:^{
                [[MEModel sharedInstance].HUD dismissAnimated:YES];
            }];
            break;
        }
        case MEShareOptionInstagram: {
            [self dismissShareView];
            [[MEModel sharedInstance].HUD showInView:self.view animated:YES];
            
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
                [[MEModel sharedInstance].HUD dismissAnimated:YES];
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
            [[MEModel sharedInstance].HUD showInView:self.view animated:YES];
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeImageDataToSavedPhotosAlbum:[[[MEModel sharedInstance] selectedImage] imageData]
                                             metadata:nil
                                      completionBlock:^(NSURL *assetURL, NSError *error) {
                                          [[MEModel sharedInstance].HUD dismissAnimated:YES];
                                          
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
    [self.captureButton setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.shareView setY:self.viewFinder.bottom];
    } completion:nil];
}

- (void)dismissShareView
{
    [self.viewFinder dismissImage];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.shareView setY:self.view.bottom];
    } completion:^(BOOL finished) {
        [self.captureButton setUserInteractionEnabled:YES];
    }];
}

#pragma mark -
#pragma mark Other Delegate methods
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        [self clearInterface];
    }
}

- (void)didReceiveMemoryWarning
{
    [[self.sectionsManager imageCache] removeAllObjects];
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end

