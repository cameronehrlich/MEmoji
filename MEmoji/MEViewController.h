//
//  MEViewController.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 7/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEMEmojiCell.h"

@import MessageUI;
@import MobileCoreServices;

@interface MEViewController : UIViewController <UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (assign, nonatomic) BOOL editing;

- (IBAction)editToggle:(id)sender;

@end
