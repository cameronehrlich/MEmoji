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
#import "MESettingsCell.h"

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
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.width*4, self.scrollView.height)];
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
    [self.scrollView addSubview:self.sectionsManager.libraryCollectionView];
    
    self.sectionsManager.libraryHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width * 0, 0, self.scrollView.width, captureButtonDiameter/2)];
    [self.sectionsManager.libraryHeader.leftButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
    [self.sectionsManager.libraryHeader.leftButton setTransform:CGAffineTransformMakeScale(1, 1)];
    [self.sectionsManager.libraryHeader.leftButton setTag:MEHeaderButtonTypeDelete];
    [self.sectionsManager.libraryHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.sectionsManager.libraryHeader.titleLabel setText:@"My MEmoji"];
    [self.sectionsManager.libraryHeader.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
    [self.sectionsManager.libraryHeader.rightButton setTag:MEHeaderButtonTypeRightArrow];
    [self.sectionsManager.libraryHeader.rightButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.sectionsManager.libraryHeader];

    // Free Pack
    self.sectionsManager.freeCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.scrollView.width * 1, 0, self.scrollView.width, self.scrollView.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.sectionsManager.freeCollectionView setDelegate:self.sectionsManager];
    [self.sectionsManager.freeCollectionView setDataSource:self.sectionsManager];
    [self.sectionsManager.freeCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.sectionsManager.freeCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.sectionsManager.freeCollectionView setAlwaysBounceVertical:YES];
    [self.sectionsManager.freeCollectionView setAllowsMultipleSelection:YES];
    [self.scrollView addSubview:self.sectionsManager.freeCollectionView];
    
    self.sectionsManager.freeHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width * 1, 0, self.scrollView.width, captureButtonDiameter/2)];
    [self.sectionsManager.freeHeader.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
    [self.sectionsManager.freeHeader.leftButton setTag:MEHeaderButtonTypeLeftArrow];
    [self.sectionsManager.freeHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.sectionsManager.freeHeader.titleLabel setText:@"Free Pack"];
    [self.sectionsManager.freeHeader.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
    [self.sectionsManager.freeHeader.rightButton setTag:MEHeaderButtonTypeRightArrow];
    [self.sectionsManager.freeHeader.rightButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.sectionsManager.freeHeader.purchaseButton setTitle:@"More Packs" forState:UIControlStateNormal];
    [self.sectionsManager.freeHeader.purchaseButton setTag:MEHeaderButtonTypeRightArrow];
    [self.sectionsManager.freeHeader.purchaseButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.scrollView addSubview:self.sectionsManager.freeHeader];
    
    // Hip-Hop Pack
    self.sectionsManager.hipHopCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.scrollView.width * 2, 0, self.scrollView.width, self.scrollView.height)
                                                     collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.sectionsManager.hipHopCollectionView setDelegate:self.sectionsManager];
    [self.sectionsManager.hipHopCollectionView setDataSource:self.sectionsManager];
    [self.sectionsManager.hipHopCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.sectionsManager.hipHopCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.sectionsManager.hipHopCollectionView setAlwaysBounceVertical:YES];
    [self.sectionsManager.hipHopCollectionView setAllowsMultipleSelection:YES];
    [self.scrollView addSubview:self.sectionsManager.hipHopCollectionView];
    
    self.sectionsManager.hipHopHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width * 2, 0, self.scrollView.width, captureButtonDiameter/2)];
    [self.sectionsManager.hipHopHeader.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
    [self.sectionsManager.hipHopHeader.leftButton setTag:MEHeaderButtonTypeLeftArrow];
    [self.sectionsManager.hipHopHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.sectionsManager.hipHopHeader.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
    [self.sectionsManager.hipHopHeader.rightButton setTag:MEHeaderButtonTypeRightArrow];
    [self.sectionsManager.hipHopHeader.rightButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.sectionsManager.hipHopHeader.titleLabel setText:@"Hip Hop Pack"];

    [self.sectionsManager.hipHopHeader.purchaseButton setTag:MEHeaderButtonTypePurchaseHipHopPack];
    [self.sectionsManager.hipHopHeader.purchaseButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.sectionsManager.hipHopHeader];
    
    // Settings page
    self.sectionsManager.settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.scrollView.width * 3, 0, self.scrollView.width, self.scrollView.height) style:UITableViewStylePlain];
    [self.sectionsManager.settingsTableView registerClass:[MESettingsCell class] forCellReuseIdentifier:@"SettingsCell"];
    [self.sectionsManager.settingsTableView setDelegate:self.sectionsManager];
    [self.sectionsManager.settingsTableView setDataSource:self.sectionsManager];
    [self.sectionsManager.settingsTableView setContentInset:UIEdgeInsetsMake(2 + captureButtonDiameter/2, 0, 0, 0)];
    [self.sectionsManager.settingsTableView setBackgroundColor:[UIColor clearColor]];
    [self.sectionsManager.settingsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.sectionsManager.settingsTableView setSeparatorColor:[UIColor clearColor]];
    [self.scrollView addSubview:self.sectionsManager.settingsTableView];
    
    self.sectionsManager.settingsHeader = [[MESectionHeaderView alloc] initWithFrame:CGRectMake(self.scrollView.width *3, 0, self.scrollView.width, captureButtonDiameter/2)];
    [self.sectionsManager.settingsHeader.titleLabel setText:@"Settings"];
    [self.sectionsManager.settingsHeader.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
    [self.sectionsManager.settingsHeader.leftButton setTag:MEHeaderButtonTypeLeftArrow];
    [self.sectionsManager.settingsHeader.leftButton addTarget:self action:@selector(headerButtonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.sectionsManager.settingsHeader];
    
    self.shareView = [[MEShareView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.width, self.scrollView.height)];
    [self.shareView setDelegate:self];
    [self.shareView setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.9]];
    [self.shareView setBottom:self.viewFinder.bottom];
    [self.shareView setHidden:YES];
    [self.view addSubview:self.shareView];
    
    // Capture Button
    CGRect captureButtonFrame = CGRectMake(0, 0, captureButtonDiameter, captureButtonDiameter);
    self.captureButton = [[MECaptureButton alloc] initWithFrame:captureButtonFrame];
    [self.captureButton setCenter:CGPointMake(self.viewFinder.centerX, self.viewFinder.bottom)];
    [self.view addSubview:self.captureButton];
    
    // Gestures
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.captureButton addGestureRecognizer:singleTapRecognizer];
    UILongPressGestureRecognizer *longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [longPressRecognier setMinimumPressDuration:0.2];
    [self.captureButton addGestureRecognizer:longPressRecognier];
    
    [self updateViewFinderButtons];
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.width, 0)];
    [self setUpObservers];
}

- (void)setUpObservers
{
    // instruction Label
    [RACObserve([MEModel sharedInstance], currentImages) subscribeNext:^(id x) {
        if ([[[MEModel sharedInstance] currentImages] count] == 0) {
            [self.instructionsLabel setHidden:NO];
            [self.instructionsLabel startShimmering];
        }else{
            [self.instructionsLabel stopShimmering];
            [self.instructionsLabel setHidden:YES];
        }
    }];
    
    // HipHop Pack
    [RACObserve([MEModel sharedInstance], hipHopPackEnabled) subscribeNext:^(id x) {
        if (x) {
            [self.sectionsManager.hipHopHeader.purchaseButton setTitle:@"Unlocked!" forState:UIControlStateNormal];
            [self.sectionsManager.hipHopHeader.purchaseButton setUserInteractionEnabled:NO];
            [self.sectionsManager.hipHopCollectionView setAlpha:1];
            [self.sectionsManager.hipHopCollectionView reloadData];
        }else{
            [self.sectionsManager.hipHopHeader.purchaseButton setUserInteractionEnabled:YES];
            [self.sectionsManager.hipHopCollectionView setAlpha:0.55];
            [self.sectionsManager.hipHopCollectionView reloadData];
        }
    }];
    
    [RACObserve([MEModel sharedInstance], hipHopPackProduct) subscribeNext:^(id x) {
        if (![[MEModel sharedInstance] hipHopPackEnabled]) {

            [self.sectionsManager.hipHopCollectionView setAlpha:0.55];

            if (x) {
                NSString *priceString = [MEModel formattedPriceForProduct:x];
                [self.sectionsManager.hipHopHeader.purchaseButton setTitle:[NSString stringWithFormat:@"Buy %@", priceString] forState:UIControlStateNormal];
                [self.sectionsManager.hipHopHeader.purchaseButton setUserInteractionEnabled:YES];
            }else{
                [self.sectionsManager.hipHopHeader.purchaseButton setTitle:@"Buy" forState:UIControlStateNormal];
                [self.sectionsManager.hipHopHeader.purchaseButton setUserInteractionEnabled:NO];
            }
        }
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES]; // iPad ios 7å
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:@"MainView"];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createAppView] build]];
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
    if (![[[MEModel sharedInstance] videoFileOutput] isRecording]) {
        [[MEModel sharedInstance] setCapturingStill:YES];
        [self startRecording];
    }
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (![[[MEModel sharedInstance] videoFileOutput] isRecording]) {
            [[MEModel sharedInstance] setCapturingStill:NO];
            [self startRecording];
            [self.viewFinder.progressView startAnimationWithCompletion:^{
                [sender setEnabled:NO];
                [sender setEnabled:YES];
                [self.viewFinder.progressView reset];
            }];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded ||
             sender.state == UIGestureRecognizerStateCancelled ||
             sender.state == UIGestureRecognizerStateFailed) { // TODO : This can be done cleverly with a bitmask; im being lazy
        [self.viewFinder.progressView reset];
        [self finishRecording];
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
        if (error){ NSLog(@"Error: %@", error); return;}
    }

    NSURL *url = [NSURL fileURLWithPath:path];
    [self.captureButton scaleUp];
    [[[MEModel sharedInstance] videoFileOutput] startRecordingToOutputFileURL:url recordingDelegate:self];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    if ([[MEModel sharedInstance] capturingStill]) {
        [self finishRecording];
    }
}

- (void)finishRecording // Be careful not to call this without calling startRecording beforehand
{
    [self.captureButton setUserInteractionEnabled:NO];

    if ([[MEModel sharedInstance] videoFileOutput].isRecording) {
        [self.captureButton startSpinning];
        [self.captureButton scaleDown];
        [[[MEModel sharedInstance] videoFileOutput] stopRecording];
    }else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // TRY HARD
            [self finishRecording];
        });
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        NSLog(@"Error in %s, %@", __PRETTY_FUNCTION__, error.debugDescription);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video could not be converted for some reason!\nTry again!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        return;
    }
    [self captureGIF];
}

- (void)captureGIF
{
    [self.sectionsManager.libraryCollectionView setAllowsMultipleSelection:NO];
    [self.sectionsManager.libraryCollectionView reloadData];
    
    NSMutableArray *overlaysToRender = [[NSMutableArray alloc] init];
    
    // Add mask first
    if (self.viewFinder.showingMask) {
        [overlaysToRender addObject:[UIImage imageNamed:@"maskLayer"]];
    }
    
    for (MEOverlayImage *overlayImage in [[MEModel sharedInstance] currentOverlays]) {
        [overlaysToRender addObject:overlayImage.image];
    }
    
    // Finally, add watermark layer
    if (YES) { // TODO : Allow user to disable watermark somehow
        [overlaysToRender addObject:[UIImage imageNamed:@"waterMark"]];
    }
    
    [[MEModel sharedInstance] createImageAnimated:![[MEModel sharedInstance] capturingStill]
                                     withOverlays:[overlaysToRender copy]
                                         complete:^{
                                             [self.captureButton stopSpinning];
                                             [self.captureButton setUserInteractionEnabled:YES];
                                             
                                             [[MEModel sharedInstance] reloadCurrentImages];
                                             [self.sectionsManager.libraryCollectionView reloadData];
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
            }];
            break;
        }
        default:
            break;
    }
}

- (void)tappedSettingsButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if (![MFMailComposeViewController canSendMail]) {
            [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"It appears your device is not setup to send mail.\nPlease email us at support@luckybunnyapps.com" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
            return;
        }else{
            [[[MEModel sharedInstance] HUD] showInView:self.view];
            
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            [mailController setMailComposeDelegate:self];
            [mailController setSubject:@"MEmoji Support"];
            [mailController setMessageBody:@"Dear MEmoji support team,\n" isHTML:NO];
            [mailController setToRecipients:[NSArray arrayWithObject:@"support@luckybunnyapps.com"]];
            [self presentViewController:mailController animated:YES completion:^{
                [[[MEModel sharedInstance] HUD] dismiss];
            }];
        }
    }else if (buttonIndex == 1){
        //
    }else if (buttonIndex == 2){
        [[[MEModel sharedInstance] HUD] showInView:self.view];
        [[MEModel sharedInstance] restorePurchasesCompletion:^(BOOL success) {
            [[[MEModel sharedInstance] HUD] dismiss];
            if (success) {
                [[[UIAlertView alloc] initWithTitle:@"Restored!" message:@"All of your previous purchases have been restored!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
            }else{
                [[[UIAlertView alloc] initWithTitle:@"Failed!" message:@"We could not find any purchases to restore at this time.\nPlease contact support@luckybunnyapps.com if you believe this is an error." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
            }
        }];
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
                               message:@"How you would like to\nsave your MEmoji?"
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
                                          
                                          if (![[[[MEModel sharedInstance] selectedImage] animated] boolValue]) {
                                              [[[UIAlertView alloc] initWithTitle:@"Oops"
                                                                          message:@"Non-animated GIFs can't be saved as videos...Silly!"
                                                                         delegate:nil
                                                                cancelButtonTitle:@"Okay"
                                                                 otherButtonTitles:nil, nil] show];
                                              [[MEModel sharedInstance].HUD dismissAnimated:YES];
                                              return;
                                          }
                                          
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
            
            if (![[[[MEModel sharedInstance] selectedImage] animated] boolValue]) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeImageDataToSavedPhotosAlbum:[[[MEModel sharedInstance] selectedImage] imageData]
                                                 metadata:nil
                                          completionBlock:^(NSURL *assetURL, NSError *error) {
                                              
                                              if ([FSOpenInInstagram canSendInstagram]) {
                                                  UIImage *tmpImage = [UIImage imageWithData:[[[MEModel sharedInstance] selectedImage] imageData]];
                                                  self.instagramOpener = [[FSOpenInInstagram alloc] init];
                                                  
                                                  [self.instagramOpener postImage:tmpImage caption:@"@MEmojiApp" inView:self.view];
                                              }
                                              
                                              [[MEModel sharedInstance].HUD dismissAnimated:YES];
                                          }];
            }else{
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
                    [UIAlertView showWithTitle:@"Ready to Upload on Instagram!"
                                       message:@"You can post your MEmoji by selecting it from your library once in Instagram."
                             cancelButtonTitle:@"Go to Instagram"
                             otherButtonTitles:nil
                                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                          NSURL *instagramURL = [NSURL URLWithString:@"instagram://camera"];
                                          if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
                                              [[UIApplication sharedApplication] openURL:instagramURL];
                                          }
                                      }];
                }];
            }
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
                                                   cancelButtonTitle:@"Go to Twitter"
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
    [self.captureButton setUserInteractionEnabled:NO];
    [self.shareView setHidden:NO];
    
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
        [self.shareView setHidden:YES];
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
    NSLog(@"%s", __FUNCTION__);
    [[self.sectionsManager imageCache] removeAllObjects];
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

