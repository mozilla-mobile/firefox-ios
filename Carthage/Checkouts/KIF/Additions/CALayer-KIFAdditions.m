//
//  CALayer-KIFAdditions.m
//  Pods
//
//  Created by Radu Ciobanu on 28/01/2016.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "CALayer-KIFAdditions.h"
#import "CAAnimation+KIFAdditions.h"


@implementation CALayer (KIFAdditions)

- (float)KIF_absoluteSpeed
{
    __block float speed = 1.0f;
    [self performBlockOnAncestorLayers:^(CALayer *layer) {
        speed = speed * layer.speed;
    }];
    return speed;
}

- (BOOL)hasAnimations
{
    __block BOOL result = NO;
    [self performBlockOnDescendentLayers:^(CALayer *layer, BOOL *stop) {
      // explicitly exclude _UIParallaxMotionEffect as it is used in alertviews, and we don't want every alertview to be paused)
      BOOL hasAnimation = layer.animationKeys.count != 0 && ![layer.animationKeys isEqualToArray:@[@"_UIParallaxMotionEffect"]];
      if (hasAnimation && !layer.hidden) {
          double currentTime = CACurrentMediaTime() * [layer KIF_absoluteSpeed];

          [layer.animationKeys enumerateObjectsUsingBlock:^(NSString *animationKey, NSUInteger idx, BOOL *innerStop) {
              CAAnimation *animation = [layer animationForKey:animationKey];
              double beginTime = [animation beginTime];
              double completionTime = [animation KIF_completionTime];

              // Ignore infinitely repeating animations
              if (currentTime >= beginTime && completionTime != HUGE_VALF && currentTime < completionTime) {
                  result = YES;
                  *innerStop = YES;
                  *stop = YES;
              }
          }];
      }
    }];
    return result;
}

- (void)performBlockOnDescendentLayers:(void (^)(CALayer *layer, BOOL *stop))block
{
    BOOL stop = NO;
    [self performBlockOnDescendentLayers:block stop:&stop];
}

- (void)performBlockOnDescendentLayers:(void (^)(CALayer *, BOOL *))block stop:(BOOL *)stop
{
    block(self, stop);
    if (*stop) {
        return;
    }

    for (CALayer *layer in self.sublayers) {
        [layer performBlockOnDescendentLayers:block stop:stop];
        if (*stop) {
            return;
        }
    }
}

- (void)performBlockOnAncestorLayers:(void (^)(CALayer *))block;
{
    block(self);

    if (self.superlayer != nil) {
        [self.superlayer performBlockOnAncestorLayers:block];
    }
}

@end
