//
//  LPFeatureFlagManager.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import "LPFeatureFlagManager.h"
#import "LPCountAggregator.h"

@implementation LPFeatureFlagManager

static LPFeatureFlagManager *sharedFeatureFlagManager = nil;
static dispatch_once_t leanplum_onceToken;

+ (instancetype)sharedManager {
    dispatch_once(&leanplum_onceToken, ^{
        sharedFeatureFlagManager = [[self alloc] init];
    });
    return sharedFeatureFlagManager;
}

- (BOOL)isFeatureFlagEnabled:(nonnull NSString *)featureFlagName {
    [[LPCountAggregator sharedAggregator] incrementCount:@"is_feature_flag_enabled"];
    return [self.enabledFeatureFlags containsObject:featureFlagName];
}

@end
