//
//  MECollectionViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MECollectionViewController.h"
#import "MECaptureButton.h"

@implementation MECollectionViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _imageCache = [[NSMutableDictionary alloc] init];
        _loadingOperations = [[NSMutableDictionary alloc] init];

        _loadingQueue = [[NSOperationQueue alloc] init];
        [self.loadingQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    }
    return self;
}

#pragma mark - 
#pragma mark FlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.libraryCollectionView]) {
        CGFloat sideLength = (collectionView.bounds.size.width/2) - 3;
        return CGSizeMake(sideLength, sideLength);
    }else {
        CGFloat sideLength = (collectionView.bounds.size.width/3) - 2;
        return CGSizeMake(sideLength, sideLength);
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2 + (captureButtonDiameter/2), 2, 2, 2);
}

#pragma mark -
#pragma mark UICollectionViewDataSource and Delegate Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if ([collectionView isEqual:self.libraryCollectionView])
    {
        return [[MEModel sharedInstance] currentImages].count;
    }else if ([collectionView isEqual:self.standardCollectionView])
    {
        return [[MEModel allOverlays] count];
    }else{
        NSLog(@"Error in Number of items in section");
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([collectionView isEqual:self.standardCollectionView])
    {
        static NSString *CellIdentifier = @"OverlayCell";
        MEOverlayCell *cell = [self.standardCollectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if ([self.imageCache objectForKey:indexPath]) {
            [cell.imageView setImage:[self.imageCache objectForKey:indexPath]];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [cell.imageView setAlpha:1];
            } completion:nil];
        }else{
            [cell.imageView setImage:nil];
            
            [self.loadingQueue addOperationWithBlock:^{
                UIImage *image = [[[MEModel allOverlays] objectAtIndex:indexPath.item] image];
                [self.imageCache setObject:image forKey:indexPath];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [cell.imageView setImage:image];
                }];
            }];
        }
        return cell;
        
    }
    
    else if ([collectionView isEqual:self.libraryCollectionView])
    {
        Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
        
        static NSString *CellIdentifier = @"MEmojiCell";
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
        [cell setEditMode:self.libraryCollectionView.allowsMultipleSelection];
        
        if ([self.imageCache objectForKey:thisImage.objectID]) {
            [cell.imageView setAnimatedImage:[self.imageCache objectForKey:thisImage.objectID]];
            
        }else{
            [cell.imageView setAnimatedImage:nil];
            
            NSBlockOperation *operation = [[NSBlockOperation alloc] init];
            __weak NSBlockOperation *weakOperation = operation;
            [operation addExecutionBlock:^{
                
                FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:thisImage.imageData];
                [self.imageCache setObject:image forKey:thisImage.objectID];
                
                if (!weakOperation.isCancelled) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                        [cell.imageView setAnimatedImage:image];
                    }];
                }
            }];
            
            [self.loadingQueue addOperation:operation];
            [self.loadingOperations setObject:operation forKey:indexPath];
        }
        return cell;
    }
    else
    {
        NSLog(@"Error in %s", __PRETTY_FUNCTION__);
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSBlockOperation *operation = [self.loadingOperations objectForKey:indexPath];
    
    if (operation.isExecuting) {
        [operation cancel];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.standardCollectionView]) {
        
        MEOverlayImage *overlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didSelectOverlay:overlayImage];
        
    }else if ([collectionView isEqual:self.libraryCollectionView]){
        [[MEModel sharedInstance] setSelectedImage:[[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.item]];
        
        if (self.libraryCollectionView.allowsMultipleSelection) { // If in editing mode
            [self.libraryCollectionView performBatchUpdates:^{
                
                [[[MEModel sharedInstance] selectedImage] MR_deleteEntity];
                [[[MEModel sharedInstance] currentImages] removeObject:[[MEModel sharedInstance] selectedImage]];
                [self.libraryCollectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    
                }];
                
            } completion:^(BOOL finished) {
                [[MEModel sharedInstance] reloadCurrentImages];
            }];
            
        }else{
            [self.delegate collectionView:self.libraryCollectionView didSelectImage:[[MEModel sharedInstance] selectedImage]];
            [self.delegate presentShareView];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.standardCollectionView]) {
        MEOverlayImage *overlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didDeselctOverlay:overlayImage];
    }
}

//    MESectionHeaderView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
//                                                                           withReuseIdentifier:@"HeaderView"
//                                                                                  forIndexPath:indexPath];
//    
//    if (![collectionView isEqual:self.standardCollectionView] ) { // TODO : better check than this to see if its the furthest right
//        [view.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
//        [view.rightButton setTag:MEHeaderButtonTypeRightArrow];
//        [view.rightButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
//    }
//
//    if (![collectionView isEqual:self.libraryCollectionView]) {
//        [view.leftButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
//        [view.leftButton setTag:MEHeaderButtonTypeLeftArrow];
//        [view.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
//    }
//
//    
//    if ([collectionView isEqual:self.libraryCollectionView]) {
//        [view.titleLabel setText:@"Recents"];
//        [view.leftButton setImage:[UIImage imageNamed:@"trash"] forState:UIControlStateNormal];
//        [view.leftButton.imageView setAlpha:0.5];
//        [view.leftButton setTransform:CGAffineTransformIdentity];
//        [view.leftButton setAlpha:1];
//        [view.leftButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
//        [view.leftButton setTag:MEHeaderButtonTypeDelete];
//    }else if ([collectionView isEqual:self.standardCollectionView]) {
//        [view.titleLabel setText:@"Standard Pack"];
//        [view.purchaseButton setTitle:@"$0.99" forState:UIControlStateNormal];
//        [view.purchaseButton addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
//        [view.purchaseButton setTag:MEHeaderButtonTypePurchase]; // Eventually the enum should contain one value for each pack
//    }


#pragma mark -
#pragma mark Protocol methods

- (void)handleTap:(UIButton *)sender
{
    [self.delegate headerButtonWasTapped:sender];
}

@end
