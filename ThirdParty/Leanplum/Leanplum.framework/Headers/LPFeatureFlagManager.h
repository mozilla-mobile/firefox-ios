//
//  LPFeatureFlagManager.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 7/25/18.
//

#import <Foundation/Foundation.h>
#import "LPFeatureFlags.h"

@interface LPFeatureFlagManager : NSObject

@property (nonatomic, strong) NSSet<NSString *> * _Nullable enabledFeatureFlags;

+ (_Nonnull instancetype)sharedManager;

- (BOOL)isFeatureFlagEnabled:(nonnull NSString *)featureFlagName;

@end
