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
#import <MBProgressHUD.h>
#import <UIView+Positioning.h>
#import <UIColor+Hex.h>

#define ScrollerEmojiSize 250

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.layout = [[AWCollectionViewDialLayout alloc] initWithRadius:self.view.bounds.size.height
                                                   andAngularSpacing:17.0 andCellSize:CGSizeMake(ScrollerEmojiSize, ScrollerEmojiSize)
                                                        andAlignment:WHEELALIGNMENTCENTER andItemHeight:ScrollerEmojiSize
                                                          andXOffset:self.view.bounds.size.width/2];
    [self.collectionView setCollectionViewLayout:self.layout];
    self.imageCache = [[NSMutableDictionary alloc] init];
    [self.collectionView setShowsVerticalScrollIndicator:NO];
    
    self.header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
    [self.collectionView addSubview:self.header];
    
    self.singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [self.header addGestureRecognizer:self.singleTapRecognizer];
    
    self.longPressRecognier = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.header addGestureRecognizer:self.longPressRecognier];
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
    
    [self.collectionView reloadData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.header setAlpha:0];
        [self initializePreviewLayer];
        
        [UIView animateWithDuration:0.45 animations:^{
            [self.header setAlpha:1];
        }];
    });

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
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
}

#pragma mark -
#pragma mark UIGestureRecognizerHandlers

- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    [self startRecording];
    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stepOfGIF * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self finishRecording];
    });
}

-  (void)handleLongPress:(UILongPressGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self startRecording];
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        [self finishRecording];
    }
}

#pragma mark -
#pragma mark AVCaptureMovieFileDelegate
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"Started Recording");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"Finished Recording");
    if (error) {
        NSLog(@"Error: %@", error);
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
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
    [[[MEModel sharedInstance] fileOutput] stopRecording];
}

- (void)captureGIF
{
    NSURL *url = [NSURL fileURLWithPath:[MEModel currentVideoPath]];
    
    [[MEModel sharedInstance] createEmojiFromMovieURL:url complete:^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:NO];
        self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        [self.collectionView reloadData];
        
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
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
        cell.imageView.animatedImage = nil;
        return cell;
    }
    
    Image *thisImage = [self.currentImages objectAtIndex:MIN(indexPath.item - 1, self.currentImages.count - 1)];

    MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];

    if ([self.imageCache objectForKey:thisImage.objectID]) {
        [cell.imageView setAnimatedImage:[self.imageCache objectForKey:thisImage.objectID]];
        [UIView animateWithDuration:0.1 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
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
            [self.imageCache setObject:image forKey:thisImage.objectID];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                //Check for cancelation before proceeding. We use cellForRowAtIndexPath to make sure we get nil for a non-visible cell
                [cell.imageView setAnimatedImage:image];
                [UIView animateWithDuration:0.1 delay:0.1 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
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

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        NSLog(@"%s", __FUNCTION__);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    
    
//    CGRect cellFrameInSuperview = [self.collectionView convertRect:cellRect toView:[self.collectionView superview]];
    
//    CGPoint offset = scrollView.contentOffset;
    
//    NSLog(@"%@", NSStringFromCGPoint(offset));

        
//        
//        CGFloat centerX = cellFrameInSuperview.origin.y + (cellFrameInSuperview.size.height/2);
//        NSLog(@"%f", centerX - CGRectGetMidY(self.view.frame));
        
//        CALayer *layer = self.header.layer;
//        CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
//        rotationAndPerspectiveTransform.m34 = 1.0 / -500;
//        rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, 45.0f * M_PI / 180.0f, 1.0f, 0.0f, 0.0f);
//        layer.transform = rotationAndPerspectiveTransform;
        
//        self.header.bottom = cellFrameInSuperview.origin.y+cellFrameInSuperview.size.height;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
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
        
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        [controller setMessageComposeDelegate:self];
        
        [controller addAttachmentData:thisImage.imageData typeIdentifier:@"com.compuserve.gif" filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:controller animated:YES completion:^{
            
        }];
    }
}

@end

