//
//  LPActionContextTest.m
//  Leanplum-SDK_Example
//
//  Created by Grace on 3/28/19.
//  Copyright © 2019 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPActionContext.h"
#import "LPVarCache.h"
#import "LPConstants.h"

/**
 * Expose private class methods
 */
@interface LPActionContext(UnitTest)

@property (nonatomic, strong) NSDictionary *args;
+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;
- (void)setProperArgs;

@end

@interface LPActionContextTest : XCTestCase

@end

@implementation LPActionContextTest

- (void)setUp {
    [super setUp];
    
    // initialize the var cache to be empty and have a dummy action
    [[LPVarCache sharedCache] applyVariableDiffs:nil messages:nil updateRules:nil eventRules:nil variants:nil regions:nil variantDebugInfo:nil];
    [[LPVarCache sharedCache] registerActionDefinition:@"action" ofKind:0 withArguments:@[] andOptions:@{}];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_setProperArgs_messageWithArgs {
    // create context with current content version
    LPActionContext *context = [LPActionContext
                                actionContextWithName:@"action"
                                args:nil
                                messageId:@"1"];
    
    // apply diffs with new message to increase content version
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[LP_KEY_VARS] = @{@"key1": @"value1"};
    NSDictionary *messages = @{@"1": message};
    [[LPVarCache sharedCache] applyVariableDiffs:nil messages:messages updateRules:nil eventRules:nil variants:nil regions:nil variantDebugInfo:nil];
    
    // set args from the message in the cache
    [context setProperArgs];
    
    XCTAssertEqualObjects([context args], @{@"key1": @"value1"});
}

- (void)test_setProperArgs_messageWithNilArgs {
    // create context with current content version
    LPActionContext *context = [LPActionContext
                                actionContextWithName:@"action"
                                args:@{}
                                messageId:@"1"];
    
    // apply diffs with new message to increase content version
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    message[LP_KEY_VARS] = nil;
    NSDictionary *messages = @{@"1": message};
    [[LPVarCache sharedCache] applyVariableDiffs:nil messages:messages updateRules:nil eventRules:nil variants:nil regions:nil variantDebugInfo:nil];
    
    // set nil args from the message in the cache
    [context setProperArgs];
    
    XCTAssertEqualObjects([context args], nil);
}

- (void)test_setProperArgs_noMessage {
    // create context with current content version
    LPActionContext *context = [LPActionContext
                                actionContextWithName:@"action"
                                args:@{}
                                messageId:@"1"];
    
    // apply diffs with no message to increase content version
    NSDictionary *messages = @{};
    [[LPVarCache sharedCache] applyVariableDiffs:nil messages:messages updateRules:nil eventRules:nil variants:nil regions:nil variantDebugInfo:nil];
    
    // no message in cache, args should not be set
    [context setProperArgs];
    
    XCTAssertEqualObjects([context args], @{});
}

@end
