//
//  MEShareView.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/26/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

@import UIKit;
#import "MEModel.h"

@class MEShareView;

@protocol MEShareViewDelegate <NSObject>

- (void)shareview:(MEShareView *)shareView didSelectOption:(MEShareOption)option;

@end

@interface MEShareView : UIView

@property (nonatomic, weak) id <MEShareViewDelegate> delegate;

@end
