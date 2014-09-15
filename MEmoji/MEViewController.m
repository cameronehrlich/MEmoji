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
#import "MEOverlayCellCollectionViewCell.h"


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
    
    [self.libraryCollectionView setCollectionViewLayout:self.layout];
    [self.libraryCollectionView setAlwaysBounceVertical:YES];
    [self.libraryCollectionView setBackgroundColor:[UIColor colorWithHex:0xE5E9F7]];

    self.imageCache = [[NSMutableDictionary alloc] init];
    [self.libraryCollectionView setShowsVerticalScrollIndicator:NO];
    
    // Gestures
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.viewFinder addGestureRecognizer:self.singleTapRecognizer];
    
    self.longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.longPressRecognier setMinimumPressDuration:0.3];
    [self.viewFinder addGestureRecognizer:self.longPressRecognier];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];

    [self.libraryCollectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self initializeLayout];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
}


- (void)initializeLayout
{
    // Header
    self.viewFinder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
    [self.libraryCollectionView addSubview:self.viewFinder];
    
    // Preview Layer
    CGRect layerFrame = CGRectMake(0, 0, self.viewFinder.width, self.viewFinder.height);
    [[MEModel sharedInstance] previewLayer].frame = layerFrame;
    [self.viewFinder.layer addSublayer:[[MEModel sharedInstance] previewLayer]];
    
    CALayer *circleLayer = [CALayer layer];
    [circleLayer setFrame:layerFrame];
    [circleLayer setOpacity:0.85];
    [circleLayer setContents:(id)[UIImage imageNamed:@"maskLayer"].CGImage];
    [[[MEModel sharedInstance] previewLayer] addSublayer:circleLayer];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.viewFinder.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.viewFinder.size.width*2, self.viewFinder.size.height)];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setDirectionalLockEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:YES];
    [self.viewFinder addSubview:self.scrollView];
    
    self.overlayCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.viewFinder.width, 0, self.viewFinder.width, self.viewFinder.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.overlayCollectionView setDelegate:self];
    [self.overlayCollectionView setDataSource:self];
    [self.overlayCollectionView registerClass:[MEOverlayCellCollectionViewCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.overlayCollectionView setAlwaysBounceVertical:YES];
    [self.overlayCollectionView setBackgroundColor:[UIColor clearColor]];
    [self.overlayCollectionView setContentInset:UIEdgeInsetsMake(20, 20, 0, 20)];
    [self.scrollView addSubview:self.overlayCollectionView];

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
            
            [self.libraryCollectionView reloadData];
            [self.libraryCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.inPullMode) {
                    self.inPullMode = NO;
                    
                    Image *thisImage = [self.currentImages firstObject];
                    
                    self.messageController = [[MFMessageComposeViewController alloc] init];
                    [self.messageController setMessageComposeDelegate:self];
                    
                    [self.messageController addAttachmentData:thisImage.imageData
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
    
    self.libraryCollectionView.allowsMultipleSelection = editing;
    
    if (editing) {
        self.editBarButtonItem.title = @"Done";
    }else{
        self.editBarButtonItem.title = @"Edit";
    }
    
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
        MEOverlayCellCollectionViewCell *cell = [self.overlayCollectionView dequeueReusableCellWithReuseIdentifier:@"OverlayCell" forIndexPath:indexPath];

        UIImage *cellImage = [[MEModel allOverlays] objectAtIndex:indexPath.item];
        
        [cell.imageView setImage:cellImage];
        return cell;
    }
    
    if (indexPath.row == 0) {
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MEmojiCell" forIndexPath:indexPath];
        [cell setBackgroundColor:[UIColor clearColor]];
        cell.imageView.animatedImage = nil;
        return cell;
    }
    
    Image *thisImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];
    
    MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MEmojiCell" forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor colorWithHex:0xcE5E9F7]];
    
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.overlayCollectionView]) {
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
        self.messageController = [[MFMessageComposeViewController alloc] init];
        [self.messageController setMessageComposeDelegate:self];
        
        [self.messageController addAttachmentData:thisImage.imageData
                                   typeIdentifier:@"com.compuserve.gif"
                                         filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:self.messageController animated:YES completion:^{
            
        }];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.overlayCollectionView]) {
        return CGSizeMake(125, 125); // TODO : Dynamically size these based on screen width
    }
    return CGSizeMake(75, 75);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


#pragma mark - 
#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    CGFloat parallax = MAX(0, self.libraryCollectionView.contentOffset.y+60)/2.5;
    
    CGRect newFrame = self.viewFinder.frame;
    newFrame.origin.y = 0 + parallax;
    [self.viewFinder setFrame:newFrame];
    
    CGPoint point = [self.libraryCollectionView convertPoint:self.libraryCollectionView.origin toView:self.view];
    
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

@end

