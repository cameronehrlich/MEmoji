//
//  MERenderer.h
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/16/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AssetWriterCompletion)(NSData *data);

@interface MERenderer : NSObject

+ (void)movieFromImageArray:(NSArray *)images completion:(AssetWriterCompletion)completion;

@end
