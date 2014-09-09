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


#define ScrollerEmojiSize 220
const float AllowedLengthOfGIF = 2.0; // Seconds
const float UpdateProgress = 0.5;

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Collection View
    self.layout = [[AWCollectionViewDialLayout alloc] initWithRadius:self.view.bounds.size.height
                                                   andAngularSpacing:18.0
                                                         andCellSize:CGSizeMake(ScrollerEmojiSize, ScrollerEmojiSize)
                                                        andAlignment:WHEELALIGNMENTCENTER
                                                       andItemHeight:ScrollerEmojiSize
                                                          andXOffset:(self.view.width/2)];
    [self.collectionView setCollectionViewLayout:self.layout];
    [self.collectionView setAlwaysBounceVertical:YES];
//    [self.collectionView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"binding_dark"]]];

    [self.collectionView setBackgroundColor:[UIColor colorWithHex:0xE5E9F7]];
    self.imageCache = [[NSMutableDictionary alloc] init];
    [self.collectionView setShowsVerticalScrollIndicator:NO];
    
    // Header
    CGFloat margin = 60;
    self.header = [[UIView alloc] initWithFrame:CGRectMake(margin/2, margin/2, self.view.bounds.size.width-margin, self.view.bounds.size.width-margin)];
    [self.collectionView setContentInset:UIEdgeInsetsMake(margin/2, 0, 0, 0)];
    [self.collectionView addSubview:self.header];
    [self.collectionView sendSubviewToBack:self.header];
    
    // Gesture
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.header addGestureRecognizer:self.singleTapRecognizer];
    
    self.longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.longPressRecognier setMinimumPressDuration:0.3];
    [self.header addGestureRecognizer:self.longPressRecognier];
    
    self.swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    [self.swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight];
    [self.header addGestureRecognizer:self.swipeGestureRecognizer];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
    
    [self.collectionView reloadData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.header setAlpha:0];
        [self initializePreviewLayer];
        
        [UIView animateWithDuration:0.3 animations:^{
            [self.header setAlpha:1];
        }];
    });
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
}


- (void)initializePreviewLayer
{
    CGRect layerFrame = CGRectMake(0, 0, self.header.width, self.header.height);
    [[MEModel sharedInstance] previewLayer].frame = layerFrame;
    [self.header.layer addSublayer:[[MEModel sharedInstance] previewLayer]];
    
    CALayer *circleLayer = [CALayer layer];
    [circleLayer setFrame:layerFrame];
    [circleLayer setCornerRadius:self.header.width/2];
    [circleLayer setBackgroundColor:[UIColor whiteColor].CGColor];
    
    [[[MEModel sharedInstance] previewLayer] setMask:circleLayer];
    
    self.progressView = [[DACircularProgressView alloc] initWithFrame:self.header.bounds];
    [self.progressView setThicknessRatio:0.07];
    self.progressView.trackTintColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.progressView.progressTintColor = [UIColor colorWithHex:0x5FB3FF];
    [self.progressView setAlpha:0];
    [self.header addSubview:self.progressView];
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers

- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    [self startRecording];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stepOfGIF/2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishRecording];
    });
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
            [self startRecording];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        if ([[[MEModel sharedInstance] fileOutput] isRecording]) {
            [self finishRecording];
        }
    }
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender
{
    [self toggleCameras:self];
}

- (IBAction)toggleCameras:(id)sender
{
    [[MEModel sharedInstance] toggleCameras];
}

#pragma mark -
#pragma mark AVCaptureMovieFileDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.progressView setProgress:0.0];
        [self.progressView setAlpha:1];
    }];
    [self updateProgress:UpdateProgress/AllowedLengthOfGIF];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        NSLog(@"Error: %@", error);
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Video could not be converted for some reason!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil] show];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:0.0];
            [self.progressView setAlpha:0];
        }];
        
        [self captureGIF];
    }
}

- (void)startRecording
{
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
        [[[MEModel sharedInstance] fileOutput] stopRecording];
    }
}

- (void)updateProgress:(float)progress
{
    [self.progressView setProgress:progress animated:YES];
    
    if (progress >= 1.0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self finishRecording];
        });
        
    }else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(UpdateProgress * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[[MEModel sharedInstance] fileOutput] isRecording]) {
                [self updateProgress:progress + (UpdateProgress/AllowedLengthOfGIF)];
            }
        });
    }
}

- (void)captureGIF
{
    NSURL *url = [NSURL fileURLWithPath:[MEModel currentVideoPath]];
    
    [[MEModel sharedInstance] createEmojiFromMovieURL:url complete:^{
        
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.collectionView reloadData];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.inPullMode) {
                    self.inPullMode = NO;
                    
                    Image *thisImage = [self.currentImages firstObject];
                    
                    self.messageController = [[MFMessageComposeViewController alloc] init];
                    [self.messageController setMessageComposeDelegate:self];
                    
                    [self.messageController addAttachmentData:thisImage.paddedImageData
                                               typeIdentifier:@"com.compuserve.gif"
                                                     filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
                    
                    [self presentViewController:self.messageController animated:YES completion:^{
                        
                    }];
                }
            });
        });
    }];
}

- (IBAction)editToggle:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    _editing = editing;
    
    self.collectionView.allowsMultipleSelection = editing;
    
    if (editing) {
        self.editBarButtonItem.title = @"Done";
    }else{
        self.editBarButtonItem.title = @"Edit";
    }
    
    [self.collectionView reloadData];
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
    return self.currentImages.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MEmojiCell";
    
    if (indexPath.row == 0) {
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [cell setBackgroundColor:[UIColor clearColor]];
        cell.imageView.animatedImage = nil;
        return cell;
    }
    
    Image *thisImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];
    
    MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor colorWithHex:0xcE5E9F7]];
    
    if (!cell.maskLayer) {
        cell.maskLayer = [CAShapeLayer layer];
        [cell.maskLayer setBounds:CGRectInset(cell.layer.bounds, 10, 10)];
        [cell.maskLayer setCornerRadius:cell.maskLayer.bounds.size.width/2];
        [cell.maskLayer setBackgroundColor:[UIColor whiteColor].CGColor];
        
        [cell.layer setMask:cell.maskLayer];
        [cell.maskLayer setPosition:CGPointMake(cell.layer.bounds.size.width/2, cell.layer.bounds.size.height/2)];
    }
    
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
        //Create a block operation for loading the image into the profile image view
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
        //Add the operation to the designated background queue
        [[[MEModel sharedInstance] loadingQueue] addOperation:loadImageIntoCellOp];
    }
    
    UIImageView *deleteImageView = (UIImageView *)[cell viewWithTag:12345];
    if (self.isEditing) {
        if (!deleteImageView) {
            CGRect newFrame = cell.bounds;
            newFrame = CGRectInset(newFrame, cell.bounds.size.width*marginOfGIF/1.5, cell.bounds.size.height*marginOfGIF/1.5);
            
            deleteImageView = [[UIImageView alloc] initWithFrame:newFrame];
            deleteImageView.tag = 12345;
            [deleteImageView setImage:[UIImage imageNamed:@"deleteX"]];
            [deleteImageView setContentMode:UIViewContentModeScaleAspectFit];
            [cell addSubview:deleteImageView];
        }
        
        [deleteImageView setAlpha:1];
        
    }else{
        [deleteImageView setAlpha:0];
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    CGFloat parallax = MAX(0, self.collectionView.contentOffset.y+60)/2.5;
    
    CGRect newFrame = self.header.frame;
    newFrame.origin.y = 0 + parallax;
    [self.header setFrame:newFrame];
    
    CGPoint point = [self.collectionView convertPoint:self.collectionView.origin toView:self.view];
    
    const CGFloat pullDownLimit = 200.0;
    
    if (point.y > pullDownLimit && !self.inPullMode && ![[[MEModel sharedInstance] fileOutput] isRecording]) {
        if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
            self.inPullMode = YES;
            [self startRecording];
        }
    }
    
    if (point.y < (pullDownLimit - 10) && self.inPullMode && [[[MEModel sharedInstance] fileOutput] isRecording]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self finishRecording];
        });

    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Image *thisImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];
    
    if (self.collectionView.allowsMultipleSelection) { // If in editing mode
        [self.collectionView performBatchUpdates:^{
            
            [thisImage MR_deleteEntity];
            [self.currentImages removeObject:thisImage];
            [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                
            }];
            
        } completion:^(BOOL finished) {
            self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        }];
        
    }else{
        self.messageController = [[MFMessageComposeViewController alloc] init];
        [self.messageController setMessageComposeDelegate:self];
        
        [self.messageController addAttachmentData:thisImage.paddedImageData
                                   typeIdentifier:@"com.compuserve.gif"
                                         filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:self.messageController animated:YES completion:^{
            
        }];
    }
}

@end

