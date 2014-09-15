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
//const float AllowedLengthOfGIF = 2.0; // Seconds
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
    
    self.libraryCollectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.layout];
    [self.libraryCollectionView setDelegate:self];
    [self.libraryCollectionView setDataSource:self];
    [self.libraryCollectionView registerClass:[MEMEmojiCell class] forCellWithReuseIdentifier:@"MEmojiCell"];
    [self.libraryCollectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.libraryCollectionView setCollectionViewLayout:self.layout];
    [self.libraryCollectionView setAlwaysBounceVertical:YES];
    [self.libraryCollectionView setBackgroundColor:[UIColor colorWithHex:0xE5E9F7]];
    [self.libraryCollectionView setShowsVerticalScrollIndicator:NO];

    [self.view addSubview:self.libraryCollectionView];
    
    self.captureButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    self.captureButtonView.bottom = self.view.bottom - 30;
    self.captureButtonView.centerX = self.view.centerX;
    [self.captureButtonView setBackgroundColor:[UIColor colorWithHex:0x5FB3FF]];
    [self.captureButtonView.layer setCornerRadius:self.captureButtonView.size.width/2];
    [self.view addSubview:self.captureButtonView];
    
    // Gestures
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.captureButtonView addGestureRecognizer:self.singleTapRecognizer];
    
    self.longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.longPressRecognier setMinimumPressDuration:0.3];
    [self.captureButtonView addGestureRecognizer:self.longPressRecognier];

    self.imageCache = [[NSMutableDictionary alloc] init];
    self.currentOverlays = [[NSMutableDictionary alloc] init];
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
    [self.libraryCollectionView addSubview:self.viewFinder];
    
    // Preview Layer
    CGRect layerFrame = CGRectMake(0, 0, self.viewFinder.width, self.viewFinder.height);
    [[MEModel sharedInstance] previewLayer].frame = layerFrame;
    [self.viewFinder.layer addSublayer:[[MEModel sharedInstance] previewLayer]];
    
    self.maskingLayer = [CALayer layer];
    [self.maskingLayer setFrame:layerFrame];
    [self.maskingLayer setOpacity:0.90];
    [self.maskingLayer setContents:(id)[UIImage imageNamed:@"maskLayer"].CGImage];
    [[[MEModel sharedInstance] previewLayer] addSublayer:self.maskingLayer];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.viewFinder.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.viewFinder.size.width*2, self.viewFinder.size.height)];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.viewFinder addSubview:self.scrollView];
    
    self.overlayCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(self.viewFinder.width, 0, self.viewFinder.width, self.viewFinder.height)
                                                    collectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
    [self.overlayCollectionView setDelegate:self];
    [self.overlayCollectionView setDataSource:self];
    [self.overlayCollectionView registerClass:[MEOverlayCell class] forCellWithReuseIdentifier:@"OverlayCell"];
    [self.overlayCollectionView setAlwaysBounceVertical:YES];
    [self.overlayCollectionView setShowsHorizontalScrollIndicator:NO];
    [self.overlayCollectionView setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0.75]];
    [self.overlayCollectionView setContentInset:UIEdgeInsetsMake(0, 30, 0, 30)];
    [self.overlayCollectionView setAllowsMultipleSelection:YES];
    [self.scrollView addSubview:self.overlayCollectionView];
    
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.captureButtonView setTransform:CGAffineTransformMakeScale(1.3, 1.3)];
    } completion:nil];
    
    [self startRecording];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stepOfGIF/2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishRecording];
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.captureButtonView setTransform:CGAffineTransformIdentity];
        } completion:nil];
    });
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (![[[MEModel sharedInstance] fileOutput] isRecording]) {
            
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self.captureButtonView setTransform:CGAffineTransformMakeScale(1.3,1.3)];
            } completion:nil];
            
            [self startRecording];
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        if ([[[MEModel sharedInstance] fileOutput] isRecording]) {
            [self finishRecording];
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
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
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleLight];
        [HUD showInView:self.view];
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
        
        for (JGProgressHUD *HUD in [JGProgressHUD allProgressHUDsInView:self.view]) {
            [HUD dismiss];
        }
        
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.libraryCollectionView reloadData];
            [self.libraryCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]
                                               atScrollPosition:UICollectionViewScrollPositionTop animated:YES];

        });
    }];
}

- (IBAction)editToggle:(id)sender
{
    [self setEditing:!self.editing animated:YES];
}

- (IBAction)showOverlaysAction:(id)sender
{
    if (self.scrollView.contentOffset.x > 0) {
        [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }else{
        [self.scrollView scrollRectToVisible:self.overlayCollectionView.frame animated:YES];
    }

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
        // Move this to the custom cell
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
        self.messageController = [[MFMessageComposeViewController alloc] init];
        [self.messageController setMessageComposeDelegate:self];
        
        [self.messageController addAttachmentData:thisImage.imageData
                                   typeIdentifier:@"com.compuserve.gif"
                                         filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:self.messageController animated:YES completion:^{
            
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
    
}

@end

