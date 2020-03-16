//
//  UIScreen+KIFAdditions.m
//  KIF
//
//  Created by Steven King on 25/02/2016.
//
//

#import "UIScreen+KIFAdditions.h"

@implementation UIScreen (KIFAdditions)

- (CGFloat)majorSwipeDisplacement {
    return self.bounds.size.width * 0.5;
}

@end
