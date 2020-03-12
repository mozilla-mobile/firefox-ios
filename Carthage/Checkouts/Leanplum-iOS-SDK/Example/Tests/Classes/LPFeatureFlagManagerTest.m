//
//  LPFeatureFlagsManagerTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace on 9/18/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPFeatureFlagManager.h"
#import "LPConstants.h"

@interface LPFeatureFlagManagerTest : XCTestCase

@end

@implementation LPFeatureFlagManagerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_isFeatureFlagEnabledShouldBeTrueForEnabledFlag {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    NSString *testString = @"test";
    featureFlagManager.enabledFeatureFlags = [NSSet setWithObjects:testString, nil];
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString] == true);
}

- (void)test_isFeatureFlagEnabledShouldBeFalseForDisabledFlag {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    NSString *testString = @"test";
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString] == false);
}

- (void)test_isFeatureFlagEnabledShouldResetWhenSetToNil {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    NSString *testString = @"test";
    featureFlagManager.enabledFeatureFlags = [NSSet setWithObjects:testString, nil];
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString] == true);
    featureFlagManager.enabledFeatureFlags = nil;
    XCTAssert([featureFlagManager isFeatureFlagEnabled:testString] == false);
}

@end
