//
//  MECollectionViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEModel.h"
#import "MEMEmojiCell.h"
#import "MEOverlayCell.h"
#import "MESectionHeaderView.h"
@import FLAnimatedImage;

@import Foundation;

@protocol MESectionsManagerDelegate <NSObject>

- (void)collectionView:(UICollectionView *)collectionView didSelectOverlay:(MEOverlayImage *)overlay;
- (void)collectionView:(UICollectionView *)collectionView didDeselctOverlay:(MEOverlayImage *)overlay;
- (void)collectionView:(UICollectionView *)collectionView didSelectImage:(Image *)image;

- (void)tableView:(UITableView*)tableView tappedSettingsButtonAtIndex:(NSIndexPath *)indexPath;
- (void)presentShareView;

@end

@interface MESectionsManager : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, NSCacheDelegate>

@property (nonatomic, weak) id <MESectionsManagerDelegate> delegate;

@property (nonatomic, strong) MESectionHeaderView *libraryHeader;
@property (nonatomic, strong) UICollectionView *libraryCollectionView;

@property (nonatomic, strong) MESectionHeaderView *freeHeader;
@property (nonatomic, strong) UICollectionView *freeCollectionView;

@property (nonatomic, strong) MESectionHeaderView *holidayHeader;
@property (nonatomic, strong) UICollectionView *hipHopCollectionView;

@property (nonatomic, strong) MESectionHeaderView *hipHopHeader;
@property (nonatomic, strong) UICollectionView *holidayCollectionView;

@property (nonatomic, strong) MESectionHeaderView *settingsHeader;
@property (nonatomic, strong) UITableView *settingsTableView;

@property (strong, nonatomic) NSCache *overlaysCache;
@property (strong, nonatomic) NSCache *libraryCache;
@property (strong, nonatomic) NSOperationQueue *loadingQueue;

@end
