//
//  MEViewFinder.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 9/26/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEViewFinder.h"
#import <UIView+Positioning.h>

@implementation MEViewFinder

- (instancetype)initWithFrame:(CGRect)frame previewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
{
    self = [super initWithFrame:frame];
    if (self) {
        _previewLayer = previewLayer;
        [self.previewLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self.layer addSublayer:self.previewLayer];
        
        _maskLayer = [CALayer layer];
        [self.maskLayer setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self.maskLayer setContents:(id)[UIImage imageNamed:@"maskLayer"].CGImage];
        [self.previewLayer addSublayer:self.maskLayer];
        [self setShowingMask:NO];
        
        CGRect cornerbuttonRect = CGRectMake(0, 0, 37, 37);
        
        self.topLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.topLeftButton setFrame:cornerbuttonRect];
        
        self.topRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.topRightButton setFrame:cornerbuttonRect];
        [self.topRightButton setRight:self.right];
        
        self.bottomLeftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bottomLeftButton setFrame:cornerbuttonRect];
        [self.bottomLeftButton setBottom:self.bottom];
        
        self.bottomRightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.bottomRightButton setFrame:cornerbuttonRect];
        [self.bottomRightButton setRight:self.right];
        [self.bottomRightButton setBottom:self.bottom];
        
        _allButtons = @[self.topLeftButton, self.topRightButton, self.bottomLeftButton, self.bottomRightButton];
        
        for (UIButton *button in self.allButtons) {
            [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
            [button.imageView.layer setShadowColor:[UIColor whiteColor].CGColor];
            [button.imageView.layer setShadowOffset:CGSizeMake(0, 0)];
            [button.imageView.layer setShadowOpacity:0.85];
            [button.imageView.layer setShadowRadius:4];
            [button setShowsTouchWhenHighlighted:YES];
            [button addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
            [button setClipsToBounds:NO];
            [button.layer setMasksToBounds:NO];
            [button.imageView setClipsToBounds:NO];
            [button.imageView.layer setMasksToBounds:NO];
            [self addSubview:button];
        }
        
        // Reposition buttons
        const static CGFloat margin = 10;
        self.topLeftButton.y += margin;
        self.topLeftButton.x += margin;
        
        self.topRightButton.y += margin;
        self.topRightButton.x -= margin;

        self.bottomLeftButton.y -= margin;
        self.bottomLeftButton.x += margin;
        
        self.bottomRightButton.y -= margin;
        self.bottomRightButton.x -= margin;
        
        // Set button images
        [self.topRightButton setImage:[UIImage imageNamed:@"flipCamera"] forState:UIControlStateNormal];
        [self.bottomRightButton setImage:[UIImage imageNamed:@"deleteXBlack"] forState:UIControlStateNormal];
        [self.bottomLeftButton setImage:[UIImage imageNamed:@"recentButton"] forState:UIControlStateNormal];
        [self.topLeftButton setImage:[UIImage imageNamed:@"toggleMask"] forState:UIControlStateNormal];
        
        
        self.progressView = [[MEProgressView alloc] initWithFrame:CGRectMake(0, 0, self.width, 8) andColor:[UIColor redColor]];
        [self.progressView setDuration:lengthOfGIF];
        [self addSubview:self.progressView];
        
        _presentationView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.presentationView];
        [self.presentationView setContentMode:UIViewContentModeScaleAspectFit];
        [self.presentationView setAlpha:0];
        [self.presentationView.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.presentationView.layer setShadowOffset:CGSizeMake(0, 0)];
        [self.presentationView.layer setShadowOpacity:0.5];
        [self.presentationView.layer setShadowRadius:5];
        [self.presentationView.layer setShadowPath:[UIBezierPath bezierPathWithRect:self.presentationView.bounds].CGPath];
        [self dismissImage];
        
    }
    return self;
}

- (void)handleTap:(UIButton *)sender
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.delegate viewFinder:self didTapButton:sender];
    });
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [sender setTransform:CGAffineTransformMakeScale(1.3, 1.3)];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [sender setTransform:CGAffineTransformIdentity];
        } completion:nil];
    }];
}

- (void)setShowingMask:(BOOL)showingMask
{
    _showingMask = showingMask;
    if (showingMask) {
        [self.maskLayer setOpacity:0.7];
    }else{
        [self.maskLayer setOpacity:0];
    }
}

- (void)presentImage:(Image *)image
{
    [self.presentationView setAnimatedImage:[[FLAnimatedImage alloc] initWithAnimatedGIFData:image.imageData]];
    [self.presentationView setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    [self.presentationView setCenterY:self.bottom];
    [self.presentationView setAlpha:0];
    
    for (MEOverlayImage *overlay in [[MEModel sharedInstance] currentOverlays]) {
        [overlay.layer setOpacity:0];
    }

    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self.presentationView setTransform:CGAffineTransformMakeScale(0.95, 0.95)];
        [self.presentationView setCenter:self.center];
        [self.presentationView setAlpha:1];
        [self.previewLayer setOpacity:0.5];
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)dismissImage
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.presentationView setAlpha:0];
        [self.presentationView setBottom:self.y];
        [self.previewLayer setOpacity:1];
    } completion:^(BOOL finished) {
        [self.presentationView setAnimatedImage:nil];
        
        for (MEOverlayImage *overlay in [[MEModel sharedInstance] currentOverlays]) {
            [overlay.layer setOpacity:1];
        }
        
    }];
}

- (void)updateButtons
{
    // Hide and show the "Clear" button
    if ([[[MEModel sharedInstance] currentOverlays] count] > 0) {
        [self.bottomRightButton setUserInteractionEnabled:YES];
        [self.bottomRightButton setAlpha:1];
    }else{
        [self.bottomRightButton setUserInteractionEnabled:NO];
        [self.bottomRightButton setAlpha:0];
    }
}

@end
