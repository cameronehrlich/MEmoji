//
//  MEIntroductionView.m
//  MEmoji
//
//  Created by Cameron Ehrlich on 10/28/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "MEIntroductionView.h"

@implementation MEIntroductionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setBackgroundColor:[[UIColor grayColor] colorWithAlphaComponent:0.65]];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        [self.scrollView setPagingEnabled:YES];
        [self.scrollView setDelegate:self];
        [self.scrollView setContentSize:CGSizeMake(frame.size.width * 3, frame.size.height)];
        
        UIImageView *imageView1 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"introPage1"]];
        UIImageView *imageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"introPage2"]];
        UIImageView *imageView3 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"introPage3"]];
        
        [imageView1 setFrame:CGRectMake(frame.size.width * 0, 0, frame.size.width, frame.size.height)];
        [imageView2 setFrame:CGRectMake(frame.size.width * 1, 0, frame.size.width, frame.size.height)];
        [imageView3 setFrame:CGRectMake(frame.size.width * 2, 0, frame.size.width, frame.size.height)];
        
        [self.scrollView addSubview:imageView1];
        [self.scrollView addSubview:imageView2];
        [self.scrollView addSubview:imageView3];
        
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(advanceSlide:)];
        [self.scrollView addGestureRecognizer:self.tapRecognizer];
        
        [self addSubview:self.scrollView];
    }
    return self;
}

- (void)advanceSlide:(id)sender
{
    if (ABS(self.scrollView.contentOffset.x) == self.scrollView.bounds.size.width * 2) {
        // We're at the end
        [[self delegate] introductionViewDidComplete];
        return;
    }
    
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.scrollView setContentOffset:CGPointMake(ABS(self.scrollView.contentOffset.x) + self.scrollView.bounds.size.width, self.scrollView.contentOffset.y)];
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (ABS(scrollView.contentOffset.x) > (self.scrollView.contentSize.width - self.scrollView.bounds.size.width) + 60) {
        [[self delegate] introductionViewDidComplete];
    }
}
@end
