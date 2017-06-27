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
#import "MEPackCollectionView.h"

static const NSInteger numberOfItemsPerRow = 4;
static NSString *CellIdentifier = @"MEmojiCell";

@implementation MESectionsManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _overlaysCache = [[NSCache alloc] init];
        [_overlaysCache setCountLimit:30]; // Arbitrary, keep roughly 10 overlay thumbnails in the cache at once
        [_overlaysCache setDelegate:self];
        
        _libraryCache = [[NSCache alloc] init];
        [_libraryCache setCountLimit:numberOfGIFsToKeep*1.5]; // A little extra so we are not evicting the cache
        [_libraryCache setDelegate:self];
        
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
        CGFloat sideLength = (collectionView.bounds.size.width/2) - 1 ;
        return CGSizeMake(sideLength, sideLength);
    }else {
        CGFloat sideLength = (collectionView.bounds.size.width/numberOfItemsPerRow - 1);
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
    return UIEdgeInsetsMake((captureButtonDiameter/2), 0, 0, 0);
}

#pragma mark -
#pragma mark UICollectionViewDataSource and Delegate Methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Recents
    if ([collectionView isEqual:self.libraryCollectionView])
    {
        return [[[MEModel sharedInstance] currentImages] count];
    }
    // Free Pack
    else if ([collectionView isEqual:self.freeCollectionView])
    {
        return [[MEModel freePack] count];
    }
    // Holiday Pack
    else if ([collectionView isEqual:self.holidayCollectionView]){
        
        if ([[MEModel sharedInstance] holidayPackEnabled]) {
            [self.holidayCollectionView setAlpha:1];
        }else{
            [self.holidayCollectionView setAlpha:0.55];
        }
        return [[MEModel holidayPack] count];
    }
    // Hip Hop Pack
    else if ([collectionView isEqual:self.hipHopCollectionView]){
        
        if ([[MEModel sharedInstance] hipHopPackEnabled]) {
            [self.hipHopCollectionView setAlpha:1];
        }else{
            [self.hipHopCollectionView setAlpha:0.55];
        }
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
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
    
        [cell setEditMode:self.libraryCollectionView.allowsMultipleSelection];
        
        if ([self.libraryCache objectForKey:thisImage.objectID]) {
            [cell.imageView setAnimatedImage:[self.libraryCache objectForKey:thisImage.objectID]];
        }else{
            [cell.imageView setImage:nil];
            [cell.imageView setAnimatedImage:nil];

            __block FLAnimatedImage *image;
            
            NSBlockOperation *operation = [[NSBlockOperation alloc] init];            
            [operation addExecutionBlock:^{
                
                image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:thisImage.imageData];
                if (image) {
                    [self.libraryCache setObject:image forKey:thisImage.objectID cost:1];
                }
    
            }];
            [operation setCompletionBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [cell.imageView setAnimatedImage:image];
                });
            }];
            
            [self.loadingQueue addOperation:operation];
        }
        return cell;
    }
    
    else {
        
        MEOverlayImage *overlayImage;
        MEOverlayCell *cell;
        
        // Free Pack
        if ([collectionView isEqual:self.freeCollectionView]) {
            cell = [self.freeCollectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
            overlayImage = [[MEModel freePack] objectAtIndex:indexPath.item];
        }
        // Holiday Pack
        else if ([collectionView isEqual:self.holidayCollectionView]){
            cell = [self.holidayCollectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
            overlayImage = [[MEModel holidayPack] objectAtIndex:indexPath.item];
        }
        
        // Hip Hop Pack
        else if ([collectionView isEqual:self.hipHopCollectionView]){
            cell = [self.hipHopCollectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
            overlayImage = [[MEModel hipHopPack] objectAtIndex:indexPath.item];
        }
        else{
            NSLog(@"Error in %s", __PRETTY_FUNCTION__);
        }
        
        if ([self.overlaysCache objectForKey:overlayImage]) {
            [cell.imageView setImage:[self.overlaysCache objectForKey:overlayImage]];
        }else{
            [cell.imageView setImage:nil];
            [self.loadingQueue addOperationWithBlock:^{
                [self.overlaysCache setObject:overlayImage.thumbnail forKey:overlayImage cost:1];
                
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
    if ([collectionView isEqual:self.libraryCollectionView]) {
        [[(MEMEmojiCell *)cell imageView] stopAnimating];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.libraryCollectionView]) {
        [[(MEMEmojiCell *)cell imageView] startAnimating];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.libraryCollectionView]){
        [[MEModel sharedInstance] setSelectedImage:[[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.item]];
        
        if (self.libraryCollectionView.allowsMultipleSelection) { // If in editing mode
            
                [[[MEModel sharedInstance] selectedImage] MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [[MEModel sharedInstance] reloadCurrentImages];
                }];
        }else{
            [self.delegate collectionView:self.libraryCollectionView didSelectImage:[[MEModel sharedInstance] selectedImage]];
        }
    }
    // Free Pack
    else if ([collectionView isEqual:self.freeCollectionView]) {
        
        MEOverlayImage *overlayImage = [[MEModel freePack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didSelectOverlay:overlayImage];
        
    }
    // Holiday Pack
    else if ([collectionView isEqual:self.holidayCollectionView]){
        MEOverlayImage *overlayImage = [[MEModel holidayPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didSelectOverlay:overlayImage];
    }
    
    // Hip Hop Pack
    else if ([collectionView isEqual:self.hipHopCollectionView]){
        MEOverlayImage *overlayImage = [[MEModel hipHopPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didSelectOverlay:overlayImage];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Free Pack
    if ([collectionView isEqual:self.freeCollectionView]) {
        MEOverlayImage *overlayImage = [[MEModel freePack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didDeselctOverlay:overlayImage];
    }
    // Holiday Pack
    else if ([collectionView isEqual:self.holidayCollectionView]){
        MEOverlayImage *overlayImage = [[MEModel holidayPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didDeselctOverlay:overlayImage];
    }
    // Hip Hop Pack
    else if ([collectionView isEqual:self.hipHopCollectionView]){
        MEOverlayImage *overlayImage = [[MEModel hipHopPack] objectAtIndex:indexPath.row];
        [self.delegate collectionView:collectionView didDeselctOverlay:overlayImage];
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Test here for usability of "Unlockable" packs
    // Hip Hop Pack
    if ([collectionView isEqual:self.hipHopCollectionView]) {
        return [[MEModel sharedInstance] hipHopPackEnabled];
    }
    // Holiday Pack
    else if ([collectionView isEqual:self.holidayCollectionView]){
        return [[MEModel sharedInstance] holidayPackEnabled];
    }
    return YES;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.libraryCollectionView] && [kind isEqualToString:UICollectionElementKindSectionFooter] && [self shouldShowLoadMore]) {

        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        UIButton *loadMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [loadMoreButton setFrame:footerView.bounds];
        [loadMoreButton setTitle:@"Load more" forState:UIControlStateNormal];
        [loadMoreButton.titleLabel setFont:[MEModel mainFontWithSize:20]];
        [loadMoreButton setBackgroundColor:[MEModel mainColor]];
        [loadMoreButton addTarget:self action:@selector(loadMore:) forControlEvents:UIControlEventTouchUpInside];
        [footerView addSubview:loadMoreButton];
        
        UILabel *limitWarningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2*(footerView.bounds.size.height/3), footerView.bounds.size.width, footerView.bounds.size.height/3)];
        [limitWarningLabel setFont:[MEModel mainFontWithSize:9]];
        [limitWarningLabel setAdjustsFontSizeToFitWidth:YES];
        [limitWarningLabel setTextAlignment:NSTextAlignmentCenter];
        [limitWarningLabel setText:[NSString stringWithFormat:@"MEmoji only saves your last %ld images.", (long)numberOfGIFsToKeep]];
        [limitWarningLabel setTextColor:[UIColor lightTextColor]];
        [footerView addSubview:limitWarningLabel];
        
        return footerView;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if ([collectionView isEqual:self.libraryCollectionView] && [self shouldShowLoadMore]) {
        return CGSizeMake(collectionView.frame.size.width, captureButtonDiameter/2);
    }
    return CGSizeZero;
}

- (void)loadMore:(id)sender
{
    [[MEModel sharedInstance] setNumberToLoad:MIN(numberOfGIFsToKeep,
                                                  [[MEModel sharedInstance] numberToLoad] + numberToLoadIncrementValue
                                                  )];
    [[MEModel sharedInstance] reloadCurrentImages];
}

- (BOOL)shouldShowLoadMore
{
    NSUInteger totalNumberOfImages = [Image MR_countOfEntities];

    // if total number of images is less that the amount needed to trigger a "Load more", NO!
    if (totalNumberOfImages <= numberToLoadIncrementValue /*also the starting value*/) {
        return NO;
    }
    
    if ([[MEModel sharedInstance] currentImages].count == numberOfGIFsToKeep) {
        return NO;
    }

    // If still more images to load, YES!
    if (totalNumberOfImages > [[MEModel sharedInstance] currentImages].count) {
        return YES;
    }
    // No more to load.
    return NO;
}

#pragma mark -
#pragma mark UITableViewDelegate and Datasource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MESettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.textLabel setFont:[MEModel mainFontWithSize:23]];
    [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    [cell.textLabel setTextColor:[UIColor lightTextColor]];
    
    switch (indexPath.row) {
        case MESettingsOptionWatermark:
            if ([[MEModel sharedInstance] watermarkProduct]) {
                [cell.textLabel setText:[NSString stringWithFormat:@"Disable Watermark %@", [MEModel formattedPriceForProduct:[[MEModel sharedInstance] watermarkProduct]]]];
            }else{
                [cell.textLabel setText:@"Disable Watermark"];
            }
            if (![[MEModel sharedInstance] watermarkEnabled]) {
                [cell.textLabel setText:@"Watermark Disabled"];
            }
            break;
        case MESettingsOptionContact:
            [cell.textLabel setText:@"Contact Us"];
            break;
        case MESettingsOptionReview:
            [cell.textLabel setText:@"Leave a Nice Review!"];
            break;
        case MESettingsOptionRestore:
            [cell.textLabel setText:@"Restore Purchases"];
            break;
        case MESettingsOptionIntroduction:
            [cell.textLabel setText:@"View Introduction"];
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
    return MESettingsOptionNumberOfTypes;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate tableView:tableView tappedSettingsButtonAtIndex:indexPath];
}

#pragma mark -
#pragma mark NSCacheDelegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    if ([cache isEqual:self.libraryCache]) {
//        NSLog(@"Trimming GIF cache.");
    }else if ([cache isEqual:self.overlaysCache]){
//        NSLog(@"Trimming OVERLAY cache.");
    }
}

@end
