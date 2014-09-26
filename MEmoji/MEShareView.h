//
//  MEShareView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/26/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;

@class MEShareView;

typedef NS_ENUM(NSUInteger, MEShareOption) {
    MEShareOptionSaveToLibrary,
    MEShareOptionInstagram,
    MEShareOptionFacebook,
    MEShareOptionTwitter,
    MEShareOptionMessages,
    MEShareOptionNone
};

@protocol MEShareViewDelegate <NSObject>

- (void)shareview:(MEShareView *)shareView didSelectOption:(MEShareOption)option;

@end

@interface MEShareView : UIView

@property (nonatomic, weak) id <MEShareViewDelegate> delegate;

@end
