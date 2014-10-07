//
//  MECollectionViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MESectionsManager.h"
#import "MECaptureButton.h"
#import "MESettingsCell.h"

@implementation MESectionsManager

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
        return [[[MEModel sharedInstance] currentImages] count];
    }else if ([collectionView isEqual:self.freeCollectionView])
    {
        return [[MEModel standardPack] count];
    }else if ([collectionView isEqual:self.hipHopCollectionView]){
        return [[MEModel hipHopPack] count];
    }
    else{
        NSLog(@"Error in Number of items in section");
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([collectionView isEqual:self.libraryCollectionView])
    {
        static NSString *CellIdentifier = @"MEmojiCell";
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];

        Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
        
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
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                         [cell.imageView setAnimatedImage:image];
                    });
                }
            }];
            
            [self.loadingQueue addOperation:operation];
            [self.loadingOperations setObject:operation forKey:indexPath];
        }
        return cell;
    }
    
    else {
        static NSString *CellIdentifier = @"OverlayCell";
        
        MEOverlayImage *overlayImage;
        MEOverlayCell *cell;
        
        if ([collectionView isEqual:self.freeCollectionView]) {
            cell = [self.freeCollectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
            overlayImage = [[MEModel standardPack] objectAtIndex:indexPath.item];
        }else if ([collectionView isEqual:self.hipHopCollectionView]){
            cell = [self.hipHopCollectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
            overlayImage = [[MEModel hipHopPack] objectAtIndex:indexPath.item];
        }else{
            NSLog(@"Error in %s", __PRETTY_FUNCTION__);
        }
        
        cell.layer.shouldRasterize = YES;
        cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        if ([self.imageCache objectForKey:@(overlayImage.hash)]) {
            [cell.imageView setImage:[self.imageCache objectForKey:@(overlayImage.hash)]];
        }else{
            [cell.imageView setImage:nil];
            [self.loadingQueue addOperationWithBlock:^{
                [self.imageCache setObject:overlayImage.thumbnail forKey:@(overlayImage.hash)];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.imageView setImage:overlayImage.thumbnail];
                });
            }];
        }
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSBlockOperation *operation = [self.loadingOperations objectForKey:indexPath];
    
    if (operation.isExecuting || !operation.isFinished) {
        [operation cancel];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.libraryCollectionView]){
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
    else if ([collectionView isEqual:self.freeCollectionView]) {
        
        MEOverlayImage *overlayImage = [[MEModel standardPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didSelectOverlay:overlayImage];
        
    }
    else if ([collectionView isEqual:self.hipHopCollectionView]){
        MEOverlayImage *overlayImage = [[MEModel hipHopPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didSelectOverlay:overlayImage];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.freeCollectionView]) {
        MEOverlayImage *overlayImage = [[MEModel standardPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didDeselctOverlay:overlayImage];
    }else if ([collectionView isEqual:self.hipHopCollectionView]){
        MEOverlayImage *overlayImage = [[MEModel hipHopPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didDeselctOverlay:overlayImage];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.hipHopCollectionView]) {
        return [[MEModel sharedInstance] hipHopPackEnabled];
    }
    return YES;
}

#pragma mark -
#pragma mark UITableViewDelegate and Datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MESettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textLabel setFont:[MEModel mainFontWithSize:26]];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    [cell.textLabel setTextColor:[UIColor lightTextColor]];
    
    switch (indexPath.row) {
        case 0:
            [cell.textLabel setText:@"Contact us"];
            break;
        case 1:
            [cell.textLabel setText:@"Leave a nice review!"];
            break;
        case 2:
            [cell.textLabel setText:@"Restore Purchases"];
            break;
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger numberOfSections = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return MAX(40, tableView.bounds.size.height/numberOfSections - (tableView.contentInset.top/numberOfSections));
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate tappedSettingsButtonAtIndex:indexPath.row];
    
    switch (indexPath.row) {
        case 0:
            // Mail
            break;
        case 1:
            // Leave a Review
            [[UIApplication sharedApplication] openURL:
             [NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=921847909&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
            break;
        case 2:
            // Restore purchases
            break;
            
        default:
            break;
    }
}

@end
