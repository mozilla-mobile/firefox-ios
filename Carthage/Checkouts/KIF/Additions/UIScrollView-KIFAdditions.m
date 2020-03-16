//
//  UIScrollView-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/22/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "UIScrollView-KIFAdditions.h"
#import "LoadableCategory.h"
#import "UIApplication-KIFAdditions.h"
#import "UIView-KIFAdditions.h"


MAKE_CATEGORIES_LOADABLE(UIScrollView_KIFAdditions)


@implementation UIScrollView (KIFAdditions)

- (void)scrollViewToVisible:(UIView *)view animated:(BOOL)animated;
{
    CGRect viewFrame = [self convertRect:view.bounds fromView:view];
    CGPoint contentOffset = self.contentOffset;
    
    if (CGRectGetMaxX(viewFrame) > self.contentOffset.x + CGRectGetWidth(self.bounds)) {
        contentOffset.x = MIN(CGRectGetMaxX(viewFrame) - CGRectGetWidth(self.bounds), CGRectGetMinX(viewFrame));
    } else if (CGRectGetMinX(viewFrame) < self.contentOffset.x) {
        contentOffset.x = MAX(CGRectGetMaxX(viewFrame) - CGRectGetWidth(self.bounds), CGRectGetMinX(viewFrame));
    }
    
    if (CGRectGetMaxY(viewFrame) > self.contentOffset.y + CGRectGetHeight(self.bounds)) {
        contentOffset.y = MIN(CGRectGetMaxY(viewFrame) - CGRectGetHeight(self.bounds), CGRectGetMinY(viewFrame));
    } else if (CGRectGetMinY(viewFrame) < self.contentOffset.y) {
        contentOffset.y = MAX(CGRectGetMaxY(viewFrame) - CGRectGetHeight(self.bounds), CGRectGetMinY(viewFrame));
    }

    UIEdgeInsets contentInset;
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            contentInset = self.adjustedContentInset;
        } else {
            contentInset = self.contentInset;
        }
#else
    contentInset = self.contentInset;
#endif
    CGFloat minX = -self.contentInset.left;
    CGFloat maxX = minX + MAX(0, self.contentSize.width + contentInset.left + contentInset.right - CGRectGetWidth(self.bounds));
    CGFloat minY = -self.contentInset.top;
    CGFloat maxY = minY + MAX(0, self.contentSize.height + contentInset.top + contentInset.bottom - CGRectGetHeight(self.bounds));
    contentOffset.x = MAX(minX, MIN(contentOffset.x, maxX));
    contentOffset.y = MAX(minY, MIN(contentOffset.y, maxY));
    
    if (!CGPointEqualToPoint(contentOffset, self.contentOffset)) {
        [self setContentOffset:contentOffset animated:animated];
        KIFRunLoopRunInModeRelativeToAnimationSpeed(kCFRunLoopDefaultMode, 0.2, false);
    }
}

@end
