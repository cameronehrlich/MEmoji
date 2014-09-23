//
//  MEViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewController.h"
#import <UIColor+Hex.h>
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>
#import <UIView+Positioning.h>
#import <UIColor+Hex.h>
#import <JGProgressHUD.h>
#import <UIView+Shimmer.h>
#import <UIAlertView+Blocks.h>
#import "MEOverlayCell.h"

#define ScrollerEmojiSize 220

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundImage"]]];
    [self.navigationItem setTitleView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headerLogo"]]];
    
    // Collection View
    self.layout = [[AWCollectionViewDialLayout alloc] initWithRadius:self.view.bounds.size.height
                                                   andAngularSpacing:18.0
                                                         andCellSize:CGSizeMake(ScrollerEmojiSize, ScrollerEmojiSize)
                                                        andAlignment:WHEELALIGNMENTCENTER
                                                       andItemHeight:ScrollerEmojiSize
                                                          andXOffset:(self.view.width/2)];
    
    self.libraryCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.layout];
    [self.libraryCollectionView setDelegate:self];
    [self.libraryCollectionView setDataSource:self];
    [self.libraryCollectionView registerClass:[MEMEmojiCell class] forCellWithReuseIdentifier:@"MEmojiCell"];
    [self.libraryCollectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.libraryCollectionView setCollectionViewLayout:self.layout];
    [self.libraryCollectionView setAlwaysBounceVertical:YES];
    [self.libraryCollectionView setScrollsToTop:YES];
    [self.libraryCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.libraryCollectionView setShowsVerticalScrollIndicator:NO];
    
    [self.view addSubview:self.libraryCollectionView];
    
    // Capture Button
    CGRect captureButtonFrame = CGRectMake(0, 0, 75, 75);
    self.captureButtonView = [[UIView alloc] initWithFrame:captureButtonFrame];
    self.captureButtonView.bottom = self.libraryCollectionView.height - captureButtonFrame.size.height;
    self.captureButtonView.centerX = self.view.centerX;
    CALayer *gradientLayer = [CALayer layer];
    [gradientLayer setCornerRadius:captureButtonFrame.size.width/2];
    [gradientLayer setFrame:captureButtonFrame];
    [gradientLayer setContents:(id)[UIImage imageNamed:@"captureButtonRed"].CGImage];
    [gradientLayer setMasksToBounds:YES];
    [self.captureButtonView.layer addSublayer:gradientLayer];
    [self.captureButtonView.layer setCornerRadius:self.captureButtonView.size.width/2];
    [self.captureButtonView.layer setShadowColor:[UIColor grayColor].CGColor];
    [self.captureButtonView.layer setShadowOffset:CGSizeMake(0, 5)];
    [self.captureButtonView.layer setShadowOpacity:0.5];
    [self.captureButtonView.layer setShadowRadius:3.7];
    [self.captureButtonView.layer setShadowPath:[UIBezierPath bezierPathWithOvalInRect:captureButtonFrame].CGPath];
    UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    [effectX setMinimumRelativeValue:@(-15.0)];
    [effectX setMaximumRelativeValue:@(15.0)];
    [effectY setMinimumRelativeValue:@(-15.0)];
    [effectY setMaximumRelativeValue:@(15.0)];
    [self.captureButtonView addMotionEffect:effectX];
    [self.captureButtonView addMotionEffect:effectY];
    [self.view addSubview:self.captureButtonView];
    
    self.captureButtonSpinnerView = [[LLARingSpinnerView alloc] initWithFrame:self.captureButtonView.bounds];
    [self.captureButtonSpinnerView setLineWidth:6.5];
    [self.captureButtonSpinnerView setAlpha:0];
    [self.captureButtonView addSubview:self.captureButtonSpinnerView];
    
    
    // Setup instruction Labels
    self.textLabelLeftOfButton = [[UILabel alloc] initWithFrame:CGRectMake(0, self.captureButtonView.frame.origin.y, self.captureButtonView.frame.origin.x, self.captureButtonView.height)];
    [self.textLabelLeftOfButton setTextAlignment:NSTextAlignmentCenter];
    [self.textLabelLeftOfButton setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:15]];
    [self.textLabelLeftOfButton setNumberOfLines:2];
    [self.textLabelLeftOfButton setTextColor:[UIColor grayColor]];
    [self.textLabelLeftOfButton setText:@"Tap button\nfor still."];
    
    self.textLabelRightOfButton = [[UILabel alloc] initWithFrame:CGRectMake(self.captureButtonView.right, self.captureButtonView.frame.origin.y, self.captureButtonView.frame.origin.x, self.captureButtonView.height)];
    [self.textLabelRightOfButton setTextAlignment:NSTextAlignmentCenter];
    [self.textLabelRightOfButton setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:15]];
    [self.textLabelRightOfButton setNumberOfLines:2];
    [self.textLabelRightOfButton setTextColor:[UIColor grayColor]];
    [self.textLabelRightOfButton setText:@"Press and hold\nfor GIF."];
    
    [self.view addSubview:self.textLabelLeftOfButton];
    [self.view addSubview:self.textLabelRightOfButton];
    
    // Gestures
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.captureButtonView addGestureRecognizer:singleTapRecognizer];
    
    UILongPressGestureRecognizer *longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [longPressRecognier setMinimumPressDuration:0.2];
    [self.captureButtonView addGestureRecognizer:longPressRecognier];
    
    // Additional Setup
    self.imageCache = [[NSMutableDictionary alloc] init];
    self.currentOverlays = [[NSMutableArray alloc] initWithCapacity:[MEModel allOverlays].count];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.libraryCollectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.viewFinder) {
            [self initializeLayout];
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
}

- (void)initializeLayout
{
    // View Finder
    self.viewFinder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
    [self.viewFinder.layer setShadowColor:[UIColor grayColor].CGColor];
    [self.viewFinder.layer setShadowOffset:CGSizeMake(0, 4)];
    [self.viewFinder.layer setShadowOpacity:0.3];
    [self.viewFinder.layer setShadowRadius:6];
    [self.viewFinder.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.viewFinder.bounds].CGPath];
    [self.libraryCollectionView addSubview:self.viewFinder];
    
    // Preview Layer
    CGRect layerFrame = CGRectMake(0, 0, self.viewFinder.width, self.viewFinder.height);
    CGRect clipedFrame = layerFrame;
    clipedFrame.size.height -= 1; // To stop the jittery line unter the viewFinder
    [[[MEModel sharedInstance] previewLayer] setFrame:clipedFrame];
    [self.viewFinder.layer addSublayer:[[MEModel sharedInstance] previewLayer]];
    
    self.maskingLayer = [CALayer layer];
    [self.maskingLayer setFrame:layerFrame];
    [self.maskingLayer setOpacity:0.8];
    [[[MEModel sharedInstance] previewLayer] addSublayer:self.maskingLayer];
    [self setMaskEnabled:YES];
    
    // Blur or Fade view
    BOOL isiOS8 = ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion >= 8);
    if (isiOS8) {
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.previewLayerBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.previewLayerBlur.frame = self.viewFinder.bounds;
        [self.previewLayerBlur setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.2]];
        [self.previewLayerBlur setAlpha:0];
        [self.viewFinder addSubview:self.previewLayerBlur];
    }else{
        self.previewLayerFade = [[UIView alloc] initWithFrame:self.viewFinder.bounds];
        [self.previewLayerFade setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.7]];
        [self.previewLayerFade setAlpha:0];
        [self.viewFinder addSubview:self.previewLayerFade];
    }
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.viewFinder.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.viewFinder.size.width*2, self.viewFinder.size.height)];
    [self.scrollView setDelegate:self];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setScrollsToTop:NO];
    [self.viewFinder addSubview:self.scrollView];
    
    // Flip Camera Button
    CGRect cameraButtonFrame = CGRectMake(0, 0, 44, 44);
    cameraButtonFrame.origin.x = self.viewFinder.width - cameraButtonFrame.size.width - 13;
    cameraButtonFrame.origin.y = self.viewFinder.size.height - cameraButtonFrame.size.height - 6;
    self.flipCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.flipCameraButton setFrame:cameraButtonFrame];
    [self.flipCameraButton setImage:[UIImage imageNamed:@"flipCamera"] forState:UIControlStateNormal];
    [self.flipCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.flipCameraButton addTarget:self action:@selector(toggleCameras:) forControlEvents:UIControlEventTouchUpInside];
    [self.flipCameraButton.imageView setAlpha:0.7];
    [self.flipCameraButton.imageView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.flipCameraButton.imageView.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.flipCameraButton.imageView.layer setShadowOpacity:0.8];
    [self.flipCameraButton.imageView.layer setShadowRadius:0.5];
    [self.viewFinder insertSubview:self.flipCameraButton aboveSubview:self.scrollView];
    
    // Mask Toggle Button
    CGRect maskButtonFrame = CGRectMake(0, 0, 35, 35);
    maskButtonFrame.origin.x += 11;
    maskButtonFrame.origin.y = self.viewFinder.size.height - maskButtonFrame.size.height - 9;
    self.maskToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.maskToggleButton setFrame:maskButtonFrame];
    [self.maskToggleButton setImage:[UIImage imageNamed:@"toggleMask"] forState:UIControlStateNormal];
    [self.maskToggleButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.maskToggleButton addTarget:self action:@selector(toggleMask:) forControlEvents:UIControlEventTouchUpInside];
    [self.maskToggleButton.imageView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.maskToggleButton.imageView.layer setShadowOffset:CGSizeMake(0, 0)];
    [self.maskToggleButton.imageView.layer setShadowOpacity:1];
    [self.maskToggleButton.imageView.layer setShadowRadius:1];

    [self.viewFinder insertSubview:self.maskToggleButton aboveSubview:self.scrollView];
    
    
    // Overlay/Accessories Collection View
    self.overlayCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.viewFinder.width, 0, self.viewFinder.width, self.viewFinder.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.overlayCollectionView setDelegate:self];
    [self.overlayCollectionView setDataSource:self];
    [self.overlayCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.overlayCollectionView setAlwaysBounceVertical:YES];
    [self.overlayCollectionView setShowsHorizontalScrollIndicator:NO];
    [self.overlayCollectionView setShowsVerticalScrollIndicator:NO];
    [self.overlayCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.overlayCollectionView setContentInset:UIEdgeInsetsMake(15, 20, 15, 20)];
    [self.overlayCollectionView setAllowsMultipleSelection:YES];
    [self.overlayCollectionView setScrollsToTop:NO];
    [self.scrollView addSubview:self.overlayCollectionView];
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    [self setShowingOverlays:NO];
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.captureButtonView setTransform:CGAffineTransformMakeScale(1.4, 1.4)];
    } completion:nil];
    
    [self startRecording];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stepOfGIF/2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishRecording];
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.captureButtonView setTransform:CGAffineTransformIdentity];
        } completion:nil];
    });
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
            
            [self setShowingOverlays:NO];
            [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self.captureButtonView setTransform:CGAffineTransformMakeScale(1.4,1.4)];
            } completion:nil];
            
            [self startRecording];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        if ([[[MEModel sharedInstance] fileOutput] isRecording]) {
            [self finishRecording];
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self.captureButtonView setTransform:CGAffineTransformIdentity];
            } completion:nil];
        }
    }
}

#pragma mark -
#pragma mark AVCaptureMovieFileDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        NSLog(@"Error: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video could not be converted for some reason!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }else{
        [self captureGIF];
    }
}

- (void)startRecording
{
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.libraryCollectionView setContentOffset:CGPointMake(0, -self.libraryCollectionView.contentInset.top)];
    } completion:nil];
    
    NSString *path = [MEModel currentVideoPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path])
    {
        NSError *error = nil;
        [fileManager removeItemAtPath:path error:&error];
        if (error){ NSLog(@"Error: %@", error);}
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    [[[MEModel sharedInstance] fileOutput] startRecordingToOutputFileURL:url recordingDelegate:self];
}

- (void)finishRecording
{
    if ([[[MEModel sharedInstance] fileOutput] isRecording]) {
        
        [self.captureButtonSpinnerView startAnimating];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.captureButtonSpinnerView setAlpha:1];
        }];
        
        [[[MEModel sharedInstance] fileOutput] stopRecording];
    }
}

- (void)captureGIF
{
    NSURL *url = [NSURL fileURLWithPath:[MEModel currentVideoPath]];
    
    NSMutableArray *overlaysToRender = [[NSMutableArray alloc] init];
    
    // Add mask first
    if (self.maskEnabled) {
        [overlaysToRender addObject:[UIImage imageNamed:@"maskLayer"]];
    }
    

    for (MEOverlayImage *overlayImage in self.currentOverlays) {
        [overlaysToRender addObject:overlayImage.image];
    }
    
    // Finally, add watermark layer
    if (YES) {
        [overlaysToRender addObject:[UIImage imageNamed:@"waterMark"]];
    }
    
    
    [[MEModel sharedInstance] createEmojiFromMovieURL:url andOverlays:[overlaysToRender copy] complete:^{
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.captureButtonSpinnerView setAlpha:0];
        } completion:^(BOOL finished) {
            [self.captureButtonSpinnerView stopAnimating];
        }];
        
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        
        [self.libraryCollectionView reloadData];
        [self.libraryCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]
                                           atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    }];
}

- (void)toggleCameras:(id)sender
{
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.flipCameraButton setTransform:CGAffineTransformMakeScale(0.75,0.75)];
    } completion:^(BOOL finished) {
        [[MEModel sharedInstance] toggleCameras];
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.flipCameraButton setTransform:CGAffineTransformIdentity];
        } completion:nil];
    }];
}

- (IBAction)editToggle:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}

- (void)setMaskEnabled:(BOOL)maskEnabled
{
    _maskEnabled = maskEnabled;
    
    if (maskEnabled) {
        [self.maskingLayer setContents:(id)[UIImage imageNamed:@"maskLayer"].CGImage];
    }else{
        [self.maskingLayer setContents:nil];
    }
}

- (void)toggleMask:(id)sender
{
    [self setMaskEnabled:!self.maskEnabled];
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.maskToggleButton setTransform:CGAffineTransformMakeScale(0.75,0.75)];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.maskToggleButton setTransform:CGAffineTransformIdentity];
        } completion:nil];
    }];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    _editing = editing;
    [self.libraryCollectionView setAllowsMultipleSelection:editing];
    [self.libraryCollectionView reloadData];
}

#pragma mark -
#pragma mark OverlayTogelingMethods
- (IBAction)toggleOverlaysAction:(id)sender
{
    [self.libraryCollectionView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    if (self.scrollView.contentOffset.x > 0) {
        [self setShowingOverlays:NO];
    }else {
        [self setShowingOverlays:YES];
    }
}

- (void)setShowingOverlays:(BOOL)showingOverlays
{
    _showingOverlays = showingOverlays;
    if (showingOverlays) {
        [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.width, self.scrollView.contentOffset.y)];
        } completion:^(BOOL finished) {
            _showingOverlays = YES;
        }];
    }else{
        [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseIn animations:^{
            [self.scrollView setContentOffset:CGPointMake(0, 0)];
        } completion:^(BOOL finished) {
            _showingOverlays = NO;
        }];
    }
}

#pragma mark -
#pragma mark UIMessageComposeViewController Delegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark -
#pragma mark UICollectionViewDataSource and Delegate Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Hook in here to determine whether to show the instructions
    if (self.currentImages.count == 0) {
        [self.textLabelLeftOfButton setHidden:NO];
        [self.textLabelRightOfButton setHidden:NO];
        [self.textLabelLeftOfButton startShimmering];
        [self.textLabelRightOfButton startShimmering];
    }else{
        [self.textLabelLeftOfButton setHidden:YES];
        [self.textLabelRightOfButton setHidden:YES];
        [self.textLabelLeftOfButton stopShimmering];
        [self.textLabelRightOfButton stopShimmering];
    }
    
    if ([collectionView isEqual:self.libraryCollectionView]) {
        return self.currentImages.count + 1;
    }else if ([collectionView isEqual:self.overlayCollectionView]){
        return [[MEModel allOverlays] count];
    }else{
        NSLog(@"Error in Number of items in section");
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([collectionView isEqual:self.overlayCollectionView]) {
        MEOverlayCell *cell = [self.overlayCollectionView dequeueReusableCellWithReuseIdentifier:@"OverlayCell" forIndexPath:indexPath];
        UIImage *cellImage = [(MEOverlayImage *)[[MEModel allOverlays] objectAtIndex:indexPath.item] image];
        [cell.imageView setImage:cellImage];
        return cell;
    }else if ([collectionView isEqual:self.libraryCollectionView]){
        
        if (indexPath.row == 0) {
            MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MEmojiCell" forIndexPath:indexPath];
            [cell setBackgroundColor:[UIColor clearColor]];
            cell.imageView.animatedImage = nil;
            return cell;
        }
        
        Image *thisImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];
        
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MEmojiCell" forIndexPath:indexPath];
        
        [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        if ([self.imageCache objectForKey:thisImage.objectID]) {
            [cell.imageView setAnimatedImage:[self.imageCache objectForKey:thisImage.objectID]];
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [cell.imageView setAlpha:1];
            } completion:^(BOOL finished) {
                //
            }];
        }else{
            [cell.imageView setAlpha:0];
            
            NSBlockOperation *loadImageIntoCellOp = [[NSBlockOperation alloc] init];
            //Define weak operation so that operation can be referenced from within the block without creating a retain cycle
            [loadImageIntoCellOp addExecutionBlock:^(void){
                
                FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:thisImage.imageData];
                
                if (image) {
                    [self.imageCache setObject:image forKey:thisImage.objectID];
                }else{
                    NSLog(@"Tried to load nil image");
                }
                
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                    //Check for cancelation before proceeding. We use cellForRowAtIndexPath to make sure we get nil for a non-visible cell
                    [cell.imageView setAnimatedImage:image];
                    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        [cell.imageView setAlpha:1];
                    } completion:^(BOOL finished) {
                        //
                    }];
                }];
            }];
            [[[MEModel sharedInstance] loadingQueue] addOperation:loadImageIntoCellOp];
        }
        
        [cell setEditMode:self.isEditing];
        
        return cell;
    }else{
        NSLog(@"Error in %s", __PRETTY_FUNCTION__);
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.overlayCollectionView]) {

        MEOverlayImage *overlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.item];
        [overlayImage.layer setFrame:self.viewFinder.layer.bounds]; // MUST SET FRAME OR IT WONT WORK
        
        [self.maskingLayer addSublayer:overlayImage.layer];
        [self.currentOverlays addObject:overlayImage];
 
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setShowingOverlays:NO];
        });
        
    }else if ([collectionView isEqual:self.libraryCollectionView]){
        self.currentImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];
        
        if (self.libraryCollectionView.allowsMultipleSelection) { // If in editing mode
            [self.libraryCollectionView performBatchUpdates:^{
                
                [self.currentImage MR_deleteEntity];
                [self.currentImages removeObject:self.currentImage];
                [self.libraryCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    
                }];
                
            } completion:^(BOOL finished) {
                self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
            }];
            
        }else{
            
            [self presentShareView];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.overlayCollectionView]) {
        MEOverlayImage *overlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.item];
        [overlayImage.layer removeFromSuperlayer];
        [self.currentOverlays removeObject:overlayImage];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.overlayCollectionView]) {
        CGFloat sideLength = self.viewFinder.width/4;
        return CGSizeMake(sideLength, sideLength);
    }
    return CGSizeZero;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.libraryCollectionView]) {
        [[[MEModel sharedInstance] loadingQueue] cancelAllOperations]; // TODO: Test if this makes things better for real.
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.scrollView]) {
        CGFloat parallaxFactor = self.scrollView.contentOffset.x / self.scrollView.width;
        [self.previewLayerBlur setAlpha:parallaxFactor];
        [self.previewLayerFade setAlpha:parallaxFactor];
        [self.flipCameraButton setAlpha:1.0 - parallaxFactor];
        [self.maskToggleButton setAlpha:1.0 - parallaxFactor];
        
    }else if ([scrollView isEqual:self.libraryCollectionView]){
        CGFloat parallaxFactor = MAX(0, self.libraryCollectionView.contentOffset.y+self.libraryCollectionView.contentInset.top)/4.0;
        CGRect newFrame = self.viewFinder.frame;
        newFrame.origin.y = 0 + parallaxFactor;
        [self.viewFinder setFrame:newFrame];
        
    }else if ([scrollView isEqual:self.overlayCollectionView]){
        
    }
}

#pragma mark -
#pragma mark ShareView

- (void)presentShareView
{
    if (!self.shareView) {
        self.shareView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 180)];
        [self.shareView setBackgroundColor:[[MEModel mainColor] colorWithAlphaComponent:0.7]];
        
        CGFloat numberOfDivisions = 8;
        CGFloat buttonSideLength = self.shareView.width/numberOfDivisions;
        CGRect shareButtonRect = CGRectMake(0, 0, buttonSideLength, buttonSideLength);
        
        // Save to Library
        UIButton *saveToLibraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [saveToLibraryButton setFrame:shareButtonRect];
        [saveToLibraryButton setCenter:CGPointMake(1*(self.shareView.width/numberOfDivisions), self.shareView.height/2)];
        [saveToLibraryButton setImage:[UIImage imageNamed:@"saveToCameraRoll"] forState:UIControlStateNormal];
        [saveToLibraryButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [saveToLibraryButton setTag:MEShareOptionSaveToLibrary];
        [saveToLibraryButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [saveToLibraryButton setShowsTouchWhenHighlighted:YES];
        [self.shareView addSubview:saveToLibraryButton];
        
        // Instagram
        UIButton *instagramButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [instagramButton setFrame:shareButtonRect];
        [instagramButton setCenter:CGPointMake(3*(self.shareView.width/numberOfDivisions), self.shareView.height/2)];
        [instagramButton setImage:[UIImage imageNamed:@"instagram"] forState:UIControlStateNormal];
        [instagramButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [instagramButton setTag:MEShareOptionInstagram];
        [instagramButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [instagramButton setShowsTouchWhenHighlighted:YES];
        [self.shareView addSubview:instagramButton];
        
        
        // Twitter
        UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [twitterButton setFrame:shareButtonRect];
        [twitterButton setCenter:CGPointMake(5*(self.shareView.width/numberOfDivisions), self.shareView.height/2)];
        [twitterButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
        [twitterButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [twitterButton setTag:MEShareOptionTwitter];
        [twitterButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [twitterButton setShowsTouchWhenHighlighted:YES];
        [self.shareView addSubview:twitterButton];
        
        // Save to Messages
        UIButton *messgesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [messgesButton setFrame:shareButtonRect];
        [messgesButton setTransform:CGAffineTransformMakeScale(1.25, 1.25)];
        [messgesButton setCenter:CGPointMake(7*(self.shareView.width/numberOfDivisions), self.shareView.height/2)];
        [messgesButton setImage:[UIImage imageNamed:@"sms"] forState:UIControlStateNormal];
        [messgesButton setTag:MEShareOptionMessages];
        [messgesButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [messgesButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [messgesButton setShowsTouchWhenHighlighted:YES];
        [self.shareView addSubview:messgesButton];
        
        UIButton *closeXButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeXButton setFrame:shareButtonRect];
        [closeXButton setRight:self.shareView.right];
        [closeXButton setY:0];
        [closeXButton setTransform:CGAffineTransformMakeScale(0.65, 0.65)];
        [closeXButton setImage:[UIImage imageNamed:@"deleteXBlack"] forState:UIControlStateNormal];
        [closeXButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [closeXButton addTarget:self action:@selector(dismissShareView) forControlEvents:UIControlEventTouchUpInside];
        [closeXButton setShowsTouchWhenHighlighted:YES];
        [self.shareView addSubview:closeXButton];
        
    }
    
    [self.shareView setY:self.view.height];
    [self.view addSubview:self.shareView];
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.shareView setY:(self.view.height/2) - self.shareView.height/2];
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)dismissShareView
{
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationCurveEaseIn animations:^{
        [self.shareView setBottom:-1*self.view.y ];
    } completion:^(BOOL finished) {
        [self.shareView removeFromSuperview];
    }];
}


- (void)shareAction:(UIButton *)sender
{
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
    
    switch (sender.tag) {
            
        case MEShareOptionSaveToLibrary:
        {
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
                                          [library writeImageDataToSavedPhotosAlbum:[self.currentImage imageData] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                                              [HUD dismissAnimated:YES];
                                              // TODO : Confirm saved as GIF
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
                                          
                                          [[self.currentImage movieData] writeToURL:[NSURL fileURLWithPath:[MEModel currentVideoPath]] atomically:YES];
                                          
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

        case MEShareOptionMessages:
        {
            [self dismissShareView];
            [HUD showInView:self.view animated:YES];
            self.messageController = [[MFMessageComposeViewController alloc] init];
            [self.messageController setMessageComposeDelegate:self];
            [self.messageController addAttachmentData:self.currentImage.imageData
                                       typeIdentifier:@"com.compuserve.gif"
                                             filename:[NSString stringWithFormat:@"MEmoji-%@.gif", self.currentImage.createdAt.description]];
            
            [self presentViewController:self.messageController animated:YES completion:^{
                [HUD dismissAnimated:YES];
            }];
            break;
        }
        
        case MEShareOptionInstagram:
        {
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
            
            [[self.currentImage movieData] writeToURL:[NSURL fileURLWithPath:[MEModel currentVideoPath]] atomically:YES];
            
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
        
        case MEShareOptionTwitter:
        {
            [self dismissShareView];
            [HUD showInView:self.view animated:YES];
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeImageDataToSavedPhotosAlbum:[self.currentImage imageData] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
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

#pragma mark -
#pragma mark Other Delegate methods
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        [self setShowingOverlays:NO];
        
        for (MEOverlayImage *overlayImage in self.currentOverlays) {
            [overlayImage.layer removeFromSuperlayer];
        }
        
        [self.currentOverlays removeAllObjects];
        [self.overlayCollectionView reloadData];
    }
}

@end

