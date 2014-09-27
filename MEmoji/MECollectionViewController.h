//
//  MECollectionViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/25/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEMEmojiCell.h"
#import "MEOverlayCell.h"
#import "MESectionHeaderReusableView.h"
#import <FLAnimatedImageView.h>
#import <FLAnimatedImage.h>

@import Foundation;

typedef NS_ENUM(NSUInteger, MEHeaderButtonType) {
    MEHeaderButtonTypeRightArrow,
    MEHeaderButtonTypeLeftArrow,
    MEHeaderButtonTypePurchase,
    MEHeaderButtonTypeDelete,
};

@protocol MECollectionViewControllerDelegate <NSObject>

- (void)collectionView:(UICollectionView *)collectionView didSelectOverlay:(MEOverlayImage *)overlay;
- (void)collectionView:(UICollectionView *)collectionView didDeselctOverlay:(MEOverlayImage *)overlay;
- (void)headerButtonWasTapped:(UIButton *)sender;
- (void)presentShareView;

@end

@interface MECollectionViewController : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) id <MECollectionViewControllerDelegate> delegate;

@property (nonatomic, strong) UICollectionView *libraryCollectionView;
@property (nonatomic, strong) UICollectionView *standardCollectionView;
@property (nonatomic, strong) UICollectionView *hipHopCollectionView;

@property (strong, nonatomic) NSMutableDictionary *imageCache;

@end