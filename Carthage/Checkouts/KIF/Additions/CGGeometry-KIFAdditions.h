//
//  CGGeometry-KIFAdditions.h
//  KIF
//
//  Created by Eric Firestone on 5/22/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <CoreGraphics/CGGeometry.h>

CG_INLINE CGPoint CGPointCenteredInRect(CGRect bounds) {
    return CGPointMake(bounds.origin.x + bounds.size.width * 0.5f, bounds.origin.y + bounds.size.height * 0.5f);
}

CG_INLINE CGPoint CGPointMidPoint(CGPoint point1, CGPoint point2) {
    return CGPointMake((point1.x + point2.x) / 2.0f, (point1.y + point2.y) / 2.0f);
}
