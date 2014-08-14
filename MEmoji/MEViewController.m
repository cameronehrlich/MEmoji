//
//  MEViewController.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewController.h"
#import <UIColor+Hex.h>

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

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
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
    [cell.imageView setImage:[UIImage imageWithData:thisImage.imageData]];
    [cell.layer setCornerRadius:10];
    if (self.collectionView.allowsMultipleSelection) {
        cell.backgroundColor = [UIColor colorWithHex:0x9E9E9E];
    }else{
        cell.backgroundColor = [UIColor whiteColor];
    }

    return cell;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.allowsMultipleSelection) {
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
        return;
    }
    Image *thisImage = [[[MEModel sharedInstance] currentImages] objectAtIndex:indexPath.row];
    
    UIImage *paddedImage = [[MEModel sharedInstance] paddedImageFromImage:[UIImage imageWithData:thisImage.imageData]];
    
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    [controller setMessageComposeDelegate:self];
    [controller addAttachmentData:UIImagePNGRepresentation(paddedImage) typeIdentifier:@"public.png" filename:[NSString stringWithFormat:@"MEmoji-%@.png", thisImage.createdAt.description]];
    
    [self presentViewController:controller animated:YES completion:^{
        
    }];
    
}

@end

