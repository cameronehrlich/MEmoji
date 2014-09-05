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
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

-(void)viewDidDisappear:(BOOL)animated
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
    if (result == MessageComposeResultCancelled || result == MessageComposeResultFailed) {
        NSLog(@"Didn't send!");
    }
    if (result == MessageComposeResultSent) {
        NSLog(@"Sent message!");
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

#pragma mark -
#pragma mark UICollectionViewDataSource and Delegate Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[MEModel sharedInstance] currentImages].count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"MEmojiCell";
    Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];

    MEMEmojiCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell.imageView setUserInteractionEnabled:NO];
    //Create a block operation for loading the image into the profile image view
    NSBlockOperation *loadImageIntoCellOp = [[NSBlockOperation alloc] init];
    //Define weak operation so that operation can be referenced from within the block without creating a retain cycle
    __weak NSBlockOperation *weakOp = loadImageIntoCellOp;
    [loadImageIntoCellOp addExecutionBlock:^(void){
        
        FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:thisImage.imageData];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            //Check for cancelation before proceeding. We use cellForRowAtIndexPath to make sure we get nil for a non-visible cell
            if (!weakOp.isCancelled) {
                MEMEmojiCell *oldCell = (MEMEmojiCell *)[collectionView cellForItemAtIndexPath:[indexPath copy]];
                [oldCell.imageView setAnimatedImage:image];
                [[[MEModel sharedInstance] operationCache] removeObjectForKey:thisImage.objectID];
            }
        }];
    }];
    
    //Save a reference to the operation in an NSMutableDictionary so that it can be cancelled later on
    [[[MEModel sharedInstance] operationCache] setObject:loadImageIntoCellOp forKey:thisImage.objectID];
    
    //Add the operation to the designated background queue
    [[[MEModel sharedInstance] loadingQueue] addOperation:loadImageIntoCellOp];
 
    cell.imageView.image = nil;

    if (self.collectionView.allowsMultipleSelection) {
        cell.backgroundColor = [UIColor colorWithHex:0x9E9E9E];
    }else{
        cell.backgroundColor = [UIColor whiteColor];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
    //Fetch operation that doesn't need executing anymore
    NSBlockOperation *ongoingDownloadOperation = [[[MEModel sharedInstance] operationCache] objectForKey:thisImage.objectID];
    if (ongoingDownloadOperation) {
        //Cancel operation and remove from dictionary
        [ongoingDownloadOperation cancel];
        [[[MEModel sharedInstance] operationCache] removeObjectForKey:thisImage.objectID];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.allowsMultipleSelection) { // If in editing mode
        [self.collectionView performBatchUpdates:^{
            
            Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
            
            NSMutableArray *tmpImages = [[[MEModel sharedInstance] currentImages] mutableCopy];
            [tmpImages removeObject:thisImage];
            [[MEModel sharedInstance] setCurrentImages:[tmpImages copy]];
            [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];

            [thisImage MR_deleteEntity];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"Deleted %d, error: %@", success, error.description);
            }];
                
        } completion:^(BOOL finished) {
            
        }];
    }else{
        
        Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];

        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        [controller setMessageComposeDelegate:self];
        
        [controller addAttachmentData:thisImage.imageData typeIdentifier:@"com.compuserve.gif" filename:[NSString stringWithFormat:@"MEmoji-%@.gif", thisImage.createdAt.description]];
        
        [self presentViewController:controller animated:YES completion:^{
            
        }];
    }
}

@end

