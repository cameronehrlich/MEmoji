//
//  MEShareView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/26/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEShareView.h"
#import <UIView+Positioning.h>

@implementation MEShareView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat numberOfDivisions = 8;
        CGFloat buttonSideLength = self.bounds.size.width/numberOfDivisions;
        CGRect shareButtonRect = CGRectMake(0, 0, buttonSideLength, buttonSideLength);
        
        // Save to Messages
        UIButton *messgesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [messgesButton setFrame:shareButtonRect];
        [messgesButton setTransform:CGAffineTransformMakeScale(1.25, 1.25)];
        [messgesButton setCenter:CGPointMake(1*(self.bounds.size.width/numberOfDivisions), self.bounds.size.height/2)];
        [messgesButton setImage:[UIImage imageNamed:@"sms"] forState:UIControlStateNormal];
        [messgesButton setTag:MEShareOptionMessages];
        [messgesButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [messgesButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [messgesButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:messgesButton];
        
        // Instagram
        UIButton *instagramButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [instagramButton setFrame:shareButtonRect];
        [instagramButton setCenter:CGPointMake(3*(self.bounds.size.width/numberOfDivisions), self.bounds.size.height/2)];
        [instagramButton setImage:[UIImage imageNamed:@"instagram"] forState:UIControlStateNormal];
        [instagramButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [instagramButton setTag:MEShareOptionInstagram];
        [instagramButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [instagramButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:instagramButton];
        
        // Twitter
        UIButton *twitterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [twitterButton setFrame:shareButtonRect];
        [twitterButton setCenter:CGPointMake(5*(self.bounds.size.width/numberOfDivisions), self.bounds.size.height/2)];
        [twitterButton setImage:[UIImage imageNamed:@"twitter"] forState:UIControlStateNormal];
        [twitterButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [twitterButton setTag:MEShareOptionTwitter];
        [twitterButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [twitterButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:twitterButton];

        
        // Save to Library
        UIButton *saveToLibraryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [saveToLibraryButton setFrame:shareButtonRect];
        [saveToLibraryButton setCenter:CGPointMake(7*(self.bounds.size.width/numberOfDivisions), self.bounds.size.height/2)];
        [saveToLibraryButton setImage:[UIImage imageNamed:@"saveToCameraRoll"] forState:UIControlStateNormal];
        [saveToLibraryButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [saveToLibraryButton setTag:MEShareOptionSaveToLibrary];
        [saveToLibraryButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [saveToLibraryButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:saveToLibraryButton];

        
        // Close menu
        UIButton *closeXButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeXButton setFrame:shareButtonRect];
        [closeXButton setRight:self.right];
        [closeXButton setCenter:CGPointMake(closeXButton.center.x - 9, closeXButton.center.y + 9)];
        [closeXButton setTransform:CGAffineTransformMakeScale(0.85, 0.85)];
        [closeXButton setImage:[UIImage imageNamed:@"deleteXBlack"] forState:UIControlStateNormal];
        [closeXButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [closeXButton setTag:MEShareOptionNone];
        [closeXButton addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
        [closeXButton setShowsTouchWhenHighlighted:YES];
        [self addSubview:closeXButton];

    }
    return self;
}

- (void)shareAction:(UIButton *)sender
{
    [self.delegate shareview:self didSelectOption:sender.tag];
}

@end
