//
//  MEViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewController.h"
#import <UIColor+Hex.h>
#import <UIImage+animatedGIF.h>
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>
#import <UIView+Positioning.h>
#import <UIColor+Hex.h>
#import "MEOverlayCell.h"
#import <DKLiveBlurView.h>
#import <JGProgressHUD.h>

#define ScrollerEmojiSize 220

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIStatusBarStyleLightContent;
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
    
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
    [self.libraryCollectionView setBackgroundColor:[UIColor colorWithHex:0xE5E9F7]];
    [self.libraryCollectionView setShowsVerticalScrollIndicator:NO];
    
    [self.view addSubview:self.libraryCollectionView];
    
    CGRect captureButtonFrame = CGRectMake(0, 0, 80, 80);
    self.captureButtonView = [[UIView alloc] initWithFrame:captureButtonFrame];
    self.captureButtonView.bottom = self.view.bottom - 30;
    self.captureButtonView.centerX = self.view.centerX;
    [self.captureButtonView setBackgroundColor:[UIColor colorWithHex:0x5FB3FF]];
    [self.captureButtonView.layer setCornerRadius:self.captureButtonView.size.width/2];
    [self.captureButtonView.layer setShadowColor:[UIColor grayColor].CGColor];
    [self.captureButtonView.layer setShadowOffset:CGSizeMake(0, 5)];
    [self.captureButtonView.layer setShadowOpacity:0.5];
    [self.captureButtonView.layer setShadowRadius:3.7];
    [self.captureButtonView.layer setShadowPath:[UIBezierPath bezierPathWithOvalInRect:captureButtonFrame].CGPath];
    UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    [effectX setMinimumRelativeValue:@(-20.0)];
    [effectX setMaximumRelativeValue:@(20.0)];
    [effectY setMinimumRelativeValue:@(-20.0)];
    [effectY setMaximumRelativeValue:@(20.0)];
    [self.captureButtonView addMotionEffect:effectX];
    [self.captureButtonView addMotionEffect:effectY];
    [self.view addSubview:self.captureButtonView];
    
    self.captureButtonSpinnerView = [[LLARingSpinnerView alloc] initWithFrame:self.captureButtonView.bounds];
    [self.captureButtonSpinnerView setLineWidth:5];
    [self.captureButtonSpinnerView setAlpha:0];
    [self.captureButtonView addSubview:self.captureButtonSpinnerView];
    
    // Gestures
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.captureButtonView addGestureRecognizer:singleTapRecognizer];
    
    UILongPressGestureRecognizer *longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [longPressRecognier setMinimumPressDuration:0.2];
    [self.captureButtonView addGestureRecognizer:longPressRecognier];
    
    // Additional Setup
    self.imageCache = [[NSMutableDictionary alloc] init];
    self.currentOverlays = [[NSMutableDictionary alloc] init];
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
    [self.maskingLayer setOpacity:0.90];
    [self.maskingLayer setContents:(id)[UIImage imageNamed:@"maskLayer"].CGImage];
    [[[MEModel sharedInstance] previewLayer] addSublayer:self.maskingLayer];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.visualEffectView.frame = self.viewFinder.bounds;
    [self.visualEffectView setAlpha:0];
    [self.viewFinder addSubview:self.visualEffectView];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.viewFinder.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.viewFinder.size.width*2, self.viewFinder.size.height)];
    [self.scrollView setDelegate:self];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setScrollsToTop:NO];
    [self.viewFinder addSubview:self.scrollView];
    
    // Flip Camera Button
    CGRect cameraButtonFrame = CGRectMake(0, 0, 37, 37);
    cameraButtonFrame.origin.x = self.viewFinder.width - cameraButtonFrame.size.width - 13;
    cameraButtonFrame.origin.y = self.viewFinder.size.height - cameraButtonFrame.size.height - 5;
    self.flipCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.flipCameraButton setFrame:cameraButtonFrame];
    [self.flipCameraButton setImage:[UIImage imageNamed:@"flipCamera"] forState:UIControlStateNormal];
    [self.flipCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.flipCameraButton addTarget:self action:@selector(toggleCameras:) forControlEvents:UIControlEventTouchUpInside];
    [self.viewFinder insertSubview:self.flipCameraButton aboveSubview:self.scrollView];
    
    self.overlayCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.viewFinder.width, 0, self.viewFinder.width, self.viewFinder.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.overlayCollectionView setDelegate:self];
    [self.overlayCollectionView setDataSource:self];
    [self.overlayCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.overlayCollectionView setAlwaysBounceVertical:YES];
    [self.overlayCollectionView setShowsHorizontalScrollIndicator:NO];
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
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.captureButtonView setTransform:CGAffineTransformMakeScale(1.4, 1.4)];
        [self.scrollView setContentOffset:CGPointMake(0, 0)];
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
            
            [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self.captureButtonView setTransform:CGAffineTransformMakeScale(1.4,1.4)];
                [self.scrollView setContentOffset:CGPointMake(0, 0)];
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
    for (CALayer *layer in [self.currentOverlays allValues]) {
        [overlaysToRender addObject:[UIImage imageWithCGImage:(CGImageRef)layer.contents]];
    }
    
    [[MEModel sharedInstance] createEmojiFromMovieURL:url andOverlays:overlaysToRender.copy complete:^{
        
        [UIView animateWithDuration:0.5 animations:^{
            [self.captureButtonSpinnerView setAlpha:0];
        } completion:^(BOOL finished) {
            [self.captureButtonSpinnerView stopAnimating];
        }];
        
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        
        [self.libraryCollectionView reloadData];
        [self.libraryCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]
                                           atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }];
}

- (IBAction)editToggle:(id)sender
{
    [self setEditing:!self.editing animated:YES];
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

- (IBAction)showOverlaysAction:(id)sender
{
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.4 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (self.scrollView.contentOffset.x > 0) {
            [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y)];
        }else{
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.width, self.scrollView.contentOffset.y)];
        }
    } completion:nil];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    _editing = editing;
    
    self.libraryCollectionView.allowsMultipleSelection = editing;
    
    [self.libraryCollectionView reloadData];
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
    if ([collectionView isEqual:self.libraryCollectionView]) {
        return self.currentImages.count + 1;
    }else if ([collectionView isEqual:self.overlayCollectionView]){
        return [[MEModel allOverlays] count]; // TODO: Do something here
    }else{
        NSLog(@"Error in Number of items in section");
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([collectionView isEqual:self.overlayCollectionView]) {
        MEOverlayCell *cell = [self.overlayCollectionView dequeueReusableCellWithReuseIdentifier:@"OverlayCell" forIndexPath:indexPath];
        
        UIImage *cellImage = [[MEModel allOverlays] objectAtIndex:indexPath.item];
        
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
        UIImage *tmpOverlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.item];
        CALayer *tmpLayer = [CALayer layer];
        tmpLayer.frame = self.viewFinder.layer.bounds;
        tmpLayer.contents = (id)tmpOverlayImage.CGImage;
        [self.maskingLayer addSublayer:tmpLayer];
        [self.currentOverlays setObject:tmpLayer forKey:indexPath];
        return;
    }
    
    Image *thisImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];
    
    if (self.libraryCollectionView.allowsMultipleSelection) { // If in editing mode
        [self.libraryCollectionView performBatchUpdates:^{
            
            [thisImage MR_deleteEntity];
            [self.currentImages removeObject:thisImage];
            [self.libraryCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                
            }];
            
        } completion:^(BOOL finished) {
            self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        }];
        
    }else{
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
        [HUD showInView:self.view animated:YES];
        
        self.messageController = [[MFMessageComposeViewController alloc] init];
        [self.messageController setMessageComposeDelegate:self];
        
        [self.messageController addAttachmentData:thisImage.imageData
                                   typeIdentifier:@"com.compuserve.gif"
                                         filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:self.messageController animated:YES completion:^{
            [HUD dismissAnimated:YES];
        }];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.overlayCollectionView]) {
        CALayer *overlayLayer = [self.currentOverlays objectForKey:indexPath];
        [overlayLayer removeFromSuperlayer];
        [self.currentOverlays removeObjectForKey:indexPath];
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
        [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
        
        CGFloat adjustedOffset = (self.libraryCollectionView.contentOffset.y + self.libraryCollectionView.contentInset.top);
        
        if (adjustedOffset > self.viewFinder.height + self.libraryCollectionView.contentInset.top + [[UIApplication sharedApplication] statusBarFrame].size.height * 2) { // If view Finder is offscreen
            [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y)];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isEqual:self.scrollView]) {
        CGFloat parallaxFactor = self.scrollView.contentOffset.x / self.scrollView.width;
        [self.visualEffectView setAlpha:parallaxFactor];
        [self.flipCameraButton setAlpha:1.0 - parallaxFactor];
        
    }else if ([scrollView isEqual:self.libraryCollectionView]){
        CGFloat parallaxFactor = MAX(0, self.libraryCollectionView.contentOffset.y+self.libraryCollectionView.contentInset.top)/4.0;
        CGRect newFrame = self.viewFinder.frame;
        newFrame.origin.y = 0 + parallaxFactor;
        [self.viewFinder setFrame:newFrame];
        
    }else if ([scrollView isEqual:self.overlayCollectionView]){
        
    }
}

@end

