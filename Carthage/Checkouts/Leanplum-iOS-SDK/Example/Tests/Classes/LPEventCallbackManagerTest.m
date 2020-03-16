//
//  EventCallbackManagerTest.m
//  Leanplum-SDK
//
//  Created by Alexis Oyama on 7/12/17.
//  Copyright © 2017 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LPEventCallback.h"
#import "LPEventCallbackManager.h"

@interface LPEventCallbackManagerTest : XCTestCase

@end

@implementation LPEventCallbackManagerTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_event_callback
{
    // Test invoke methods.
    XCTestExpectation *responseExpectation = [self expectationWithDescription:@"response"];
    LPNetworkResponseBlock responseBlock = ^(id<LPNetworkOperationProtocol> operation, id json){
        [responseExpectation fulfill];
    };
    
    XCTestExpectation *errorExpectation = [self expectationWithDescription:@"error"];
    LPNetworkErrorBlock errorBlock = ^(NSError *error){
        [errorExpectation fulfill];
    };
    
    LPEventCallback *callback = [[LPEventCallback alloc] initWithResponseBlock:responseBlock errorBlock:errorBlock];
    XCTAssertNotNil(callback);
    XCTAssertNotNil(callback.responseBlock);
    XCTAssertNotNil(callback.errorBlock);
    
    [callback invokeResponseWithOperation:nil response:nil];
    [callback invokeError:nil];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
    
    // Test null.
    callback = [[LPEventCallback alloc] initWithResponseBlock:nil errorBlock:nil];
    XCTAssertNotNil(callback);
    XCTAssertNil(callback.responseBlock);
    XCTAssertNil(callback.errorBlock);
    [callback invokeResponseWithOperation:nil response:nil];
    [callback invokeError:nil];
}

- (void)test_event_callback_manager
{
    NSMutableDictionary *eventCallbackMap = [LPEventCallbackManager eventCallbackMap];
    XCTAssertNotNil(eventCallbackMap);
    XCTAssertTrue(eventCallbackMap.count == 0);
    
    // Null should not be added.
    [LPEventCallbackManager addEventCallbackAt:1 onSuccess:nil onError:nil];
    XCTAssertTrue(eventCallbackMap.count == 0);
    
    // Make sure error callbacks are called on bad responses.
    XCTestExpectation *badExpectation = [self expectationWithDescription:@"bad"];
    [LPEventCallbackManager addEventCallbackAt:1
                                     onSuccess:^(id operation, id json) {
        XCTAssertThrows(@"Response should not be called");
    } onError:^(NSError *error) {
        [badExpectation fulfill];
    }];
    
    [LPEventCallbackManager addEventCallbackAt:2
                                     onSuccess:nil
                                       onError:^(NSError *error) {
        XCTAssertThrows(@"Error should not be called");
    }];
    XCTAssertTrue(eventCallbackMap.count == 2);
    
    // invokeErrorCallbacksOnResponses: should execute and delete 1.
    NSDictionary *responses = @{@"response":@[
                                        @{@"success":@1},
                                        @{@"error":@{@"message":@"test_error"}},
                                        @{@"success":@1}
                                        ]};
    NSArray *requests = @[@{}, @{}, @{}];
    [LPEventCallbackManager invokeErrorCallbacksOnResponses:responses];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertTrue(eventCallbackMap.count == 1);
    
    // invokeSuccessCallbacksOnResponses should delete the rest.
    [LPEventCallbackManager invokeSuccessCallbacksOnResponses:responses requests:requests operation:nil];
    XCTAssertTrue(eventCallbackMap.count == 0);
    
    // Test on failure.
    XCTestExpectation *error1Expectation = [self expectationWithDescription:@"error1"];
    [LPEventCallbackManager addEventCallbackAt:5 onSuccess:^(id operation, id json) {
        XCTAssertThrows(@"Response should not be called");
    } onError:^(NSError *error) {
        [error1Expectation fulfill];
    }];
    
    XCTestExpectation *error2Expectation = [self expectationWithDescription:@"error2"];
    [LPEventCallbackManager addEventCallbackAt:10 onSuccess:^(id operation, id json) {
        XCTAssertThrows(@"Response should not be called");
    } onError:^(NSError *error) {
        [error2Expectation fulfill];
    }];
    XCTAssertTrue(eventCallbackMap.count == 2);
    
    [LPEventCallbackManager invokeErrorCallbacksWithError:nil];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertTrue(eventCallbackMap.count == 0);
    
    // Test if index of the map is correct for multiple requests.
    XCTestExpectation *response1Expectation = [self expectationWithDescription:@"response1"];
    [LPEventCallbackManager addEventCallbackAt:0 onSuccess:^(id operation, id json) {
        [response1Expectation fulfill];
    } onError:^(NSError *error) {
        XCTAssertThrows(@"Error should not be called");
    }];
    
    XCTestExpectation *response2Expectation = [self expectationWithDescription:@"response2"];
    [LPEventCallbackManager addEventCallbackAt:1 onSuccess:^(id operation, id json) {
        [response2Expectation fulfill];
    } onError:^(NSError *error) {
        XCTAssertThrows(@"Error should not be called");
    }];
    
    XCTestExpectation *response3Expectation = [self expectationWithDescription:@"response3"];
    [LPEventCallbackManager addEventCallbackAt:2 onSuccess:^(id operation, id json) {
        [response3Expectation fulfill];
    } onError:^(NSError *error) {
        XCTAssertThrows(@"Error should not be called");
    }];
    XCTAssertTrue(eventCallbackMap.count == 3);
    
    // First response.
    NSDictionary *reponses1 = @{@"response":@[
                                            @{@"success":@1, @"var":@"test1"},
                                            @{@"success":@1, @"var":@"test2"}
                                            ]};
    NSArray *requests1 = @[@{}, @{}];
    [LPEventCallbackManager invokeSuccessCallbacksOnResponses:reponses1
                                                     requests:requests1
                                                    operation:nil];
    [self waitForExpectations:@[response1Expectation, response2Expectation] timeout:2];
    XCTAssertTrue(eventCallbackMap.count == 1);
    
    // Second response.
    NSDictionary *reponses2 = @{@"response":@[
                                            @{@"success":@1, @"var":@"test3"}
                                            ]};
    NSArray *requests2 = @[@{}];
    [LPEventCallbackManager invokeSuccessCallbacksOnResponses:reponses2
                                                     requests:requests2
                                                    operation:nil];
    [self waitForExpectations:@[response3Expectation] timeout:2];
    XCTAssertTrue(eventCallbackMap.count == 0);
}

@end
