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
    }
    return self;
}

#pragma mark - 
#pragma mark FlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat sideLength = (collectionView.bounds.size.width/3) - 2;
    return CGSizeMake(sideLength, sideLength);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(collectionView.bounds.size.width, captureButtonDiameter/2);
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
    return UIEdgeInsetsMake(2, 2, 2, 2);
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
    }else if ([collectionView isEqual:self.hipHopCollectionView]){
        //
        return 0; // TODO
    }else{
        NSLog(@"Error in Number of items in section");
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([collectionView isEqual:self.standardCollectionView])
    {
        MEOverlayCell *cell = [self.standardCollectionView dequeueReusableCellWithReuseIdentifier:@"OverlayCell" forIndexPath:indexPath];
        
        if ([self.imageCache objectForKey:indexPath]) {
            [cell.imageView setImage:[self.imageCache objectForKey:indexPath]];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [cell.imageView setAlpha:1];
            } completion:nil];
        }else{
            [cell.imageView setAlpha:0];
            
            [[[MEModel sharedInstance] loadingQueue] addOperationWithBlock:^{
                UIImage *image = [[[MEModel allOverlays] objectAtIndex:indexPath.item] image];
                [self.imageCache setObject:image forKey:indexPath];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [cell.imageView setImage:image];
                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        [cell.imageView setAlpha:1];
                    } completion:nil];
                }];
            }];
            
        }
        return cell;
        
    }
    
    else if ([collectionView isEqual:self.libraryCollectionView])
    {
        
        Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
        
        MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MEmojiCell" forIndexPath:indexPath];
        
        if ([self.imageCache objectForKey:thisImage.objectID]) {
            [cell.imageView setAnimatedImage:[self.imageCache objectForKey:thisImage.objectID]];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [cell.imageView setAlpha:1];
            } completion:nil];
            
        }else{
            [cell.imageView setAlpha:0];
            
            [[[MEModel sharedInstance] loadingQueue] addOperationWithBlock:^{
                FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:thisImage.imageData];

                [self.imageCache setObject:image forKey:thisImage.objectID];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
                    
                    [cell.imageView setAnimatedImage:image];
                    
                    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        [cell.imageView setAlpha:1];
                    } completion:nil];
                    
                }];
            }];
        }
        return cell;
    }
    else
    {
        NSLog(@"Error in %s", __PRETTY_FUNCTION__);
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.standardCollectionView]) {
        
        MEOverlayImage *overlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.row];
        [overlayImage.layer setFrame:[self.delegate maskingLayerForViewFinder].bounds]; // MUST SET FRAME OR IT WONT WORK // TODO
        
        [[self.delegate maskingLayerForViewFinder] addSublayer:overlayImage.layer];
        [[[MEModel sharedInstance] currentOverlays] addObject:overlayImage];
        
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
            
            [self.delegate presentShareView];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([collectionView isEqual:self.standardCollectionView]) {
        MEOverlayImage *overlayImage = [[MEModel allOverlays] objectAtIndex:indexPath.item];
        [overlayImage.layer removeFromSuperlayer];
        [[[MEModel sharedInstance] currentOverlays] removeObject:overlayImage];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    MESectionHeaderReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                           withReuseIdentifier:@"HeaderView"
                                                                                  forIndexPath:indexPath];
    
    if (![collectionView isEqual:self.standardCollectionView] ) { // TODO : better check than this to see if its the furthest right
        [view.rightButton setImage:[UIImage imageNamed:@"arrowRight"] forState:UIControlStateNormal];
        [view.rightButton addTarget:self action:@selector(moveSectionsRight:) forControlEvents:UIControlEventTouchUpInside];
    }

    if (![collectionView isEqual:self.libraryCollectionView]) {
        [view.leftButton addTarget:self action:@selector(moveSectionsLeft:) forControlEvents:UIControlEventTouchUpInside];
        [view.leftButton setImage:[UIImage imageNamed:@"arrowLeft"] forState:UIControlStateNormal];
    }

    
    if ([collectionView isEqual:self.libraryCollectionView]) {
        [view.titleLabel setText:@"Recents"];
    }else if ([collectionView isEqual:self.standardCollectionView]) {
        [view.titleLabel setText:@"Standard Pack"];
        [view.purchaseButton setTitle:@"$0.99" forState:UIControlStateNormal];
    }

    return view;
}

#pragma mark -
#pragma mark Protocol methods

- (void)moveSectionsRight:(UIButton *)sender
{
    [self.delegate moveSectionsRight];
}

- (void)moveSectionsLeft:(UIButton *)sender
{
    [self.delegate moveSectionsLeft];
}
@end
