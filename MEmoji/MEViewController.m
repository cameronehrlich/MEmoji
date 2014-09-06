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

@implementation MEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.layout = [[MEFlowLayout alloc] init];
    self.layout.itemSize = CGSizeMake(140, 140);
    [self.collectionView setCollectionViewLayout:self.layout];
    self.imageCache = [[NSMutableDictionary alloc] init];
    [self.collectionView setShowsVerticalScrollIndicator:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];

    [self.collectionView reloadData];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[[MEModel sharedInstance] loadingQueue] cancelAllOperations];
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

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.currentImages.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MEmojiCell";
    
    Image *thisImage = [self.currentImages objectAtIndex:indexPath.row];

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
    if (self.collectionView.allowsMultipleSelection) { // If in editing mode
        [self.collectionView performBatchUpdates:^{

            Image *thisImage = [self.currentImages objectAtIndex:indexPath.row];
            [thisImage MR_deleteEntity];
            [self.currentImages removeObject:thisImage];
            [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {

            }];
                
        } completion:^(BOOL finished) {
            self.currentImages = [[Image MR_findAllSortedBy:@"createdAt" ascending:NO] mutableCopy];
        }];
        
    }else{
        
        Image *thisImage = [self.currentImages objectAtIndex:indexPath.row];

        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        [controller setMessageComposeDelegate:self];
        
        [controller addAttachmentData:thisImage.imageData typeIdentifier:@"com.compuserve.gif" filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:controller animated:YES completion:^{
            
        }];
    }
}

@end

