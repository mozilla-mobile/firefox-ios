//
//  ADJBackoffStrategy.m
//  Adjust
//
//  Created by Pedro Filipe on 20/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJBackoffStrategy.h"

@implementation ADJBackoffStrategy

+ (ADJBackoffStrategy *)backoffStrategyWithType:(ADJBackoffStrategyType)strategyType {
    return [[ADJBackoffStrategy alloc] initWithType:strategyType];
}

- (id) initWithType:(ADJBackoffStrategyType)strategyType {
    self = [super init];
    if (self == nil) return nil;

    switch (strategyType) {
        case ADJLongWait:
            [self saveStrategy:1
              secondMultiplier:120
                       maxWait:60*60*24
                     minRange:0.5
                     maxRange:1.0];
            break;
        case ADJShortWait:
            [self saveStrategy:1
              secondMultiplier:0.2
                       maxWait:60*60
                     minRange:0.5
                     maxRange:1.0];
            break;
        case ADJTestWait:
            [self saveStrategy:1
              secondMultiplier:0.2
                       maxWait:1
                     minRange:0.5
                     maxRange:1.0];
            break;
        case ADJNoWait:
            [self saveStrategy:100
              secondMultiplier:1
                       maxWait:1
                     minRange:0.5
                     maxRange:1.0];
            break;
        case ADJNoRetry:
            [self saveStrategy:0
              secondMultiplier:100000
                       maxWait:100000
                      minRange:0.5
                      maxRange:1.0];
            break;
        default:
            break;
    }

    return self;
}

- (void)saveStrategy:(NSInteger)minRetries
    secondMultiplier:(NSTimeInterval)secondMultiplier
             maxWait:(NSTimeInterval)maxWait
           minRange:(double)minRange
           maxRange:(double)maxRange
{
    self.minRetries = minRetries;
    self.secondMultiplier = secondMultiplier;
    self.maxWait = maxWait;
    self.minRange = minRange;
    self.maxRange = maxRange;
}

@end
