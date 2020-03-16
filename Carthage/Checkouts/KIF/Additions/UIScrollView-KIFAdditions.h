//
//  UIScrollView-KIFAdditions.h
//  KIF
//
//  Created by Eric Firestone on 5/22/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>


@interface UIScrollView (KIFAdditions)

- (void)scrollViewToVisible:(UIView *)view animated:(BOOL)animated;

@end
