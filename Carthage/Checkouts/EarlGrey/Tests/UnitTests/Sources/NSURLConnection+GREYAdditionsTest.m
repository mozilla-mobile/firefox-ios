//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <OCMock/OCMock.h>
#include <objc/runtime.h>

#import "Additions/NSObject+GREYAdditions.h"
#import "Additions/NSURLConnection+GREYAdditions.h"
#import <EarlGrey/GREYCondition.h>
#import <EarlGrey/GREYUIThreadExecutor.h>
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

@interface NSURLConnection (NSURLConnection_GREYAdditionsTest)
- (GREYAppStateTrackerObject *)objectForConnection;
@end

// Class that performs swizzled operations in dealloc to ensure they don't track.
@interface NSURLConnectionDealloc : NSURLConnection
@end

@implementation NSURLConnectionDealloc

- (void)dealloc {
  [self start];
}

@end

@interface NSURLConnection_GREYAdditionsTest : GREYBaseTest
    <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@end

@implementation NSURLConnection_GREYAdditionsTest {
  id _mockGREYAppStateTracker;
  BOOL _connectionFinished;
  NSURLRequest *_localHostRequest;
  NSURLRequest *_externalRequest;
  id _capturedPendingObject;
}

- (void)setUp {
  [super setUp];

  _connectionFinished = NO;
  _mockGREYAppStateTracker =
      [OCMockObject partialMockForObject:[GREYAppStateTracker sharedInstance]];
  _localHostRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost/"]];
  _externalRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  void (^blockPending)(NSInvocation *) = ^(NSInvocation *invocation) {
    __unsafe_unretained id object;
    [invocation getArgument:&object atIndex:3];
    _capturedPendingObject = object;
  };
  [[[[_mockGREYAppStateTracker expect] andDo:blockPending] andForwardToRealObject]
      trackState:kGREYPendingNetworkRequest forObject:OCMOCK_ANY];
  [[[_mockGREYAppStateTracker expect] andForwardToRealObject]
      untrackState:kGREYPendingNetworkRequest forObject:OCMOCK_ANY];
}

- (void)tearDown {
  [_mockGREYAppStateTracker stopMocking];
  _capturedPendingObject = nil;
  [super tearDown];
}

- (void)testConnectionClassMethodPlusDelegate {
  NSURLConnection *connection = [NSURLConnection connectionWithRequest:_localHostRequest
                                                              delegate:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
  XCTAssertEqual(connection, _capturedPendingObject, @"Unexpected object was blocked.");
}

- (void)testConnectionInitPlusDelegate {
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:_localHostRequest
                                                                delegate:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  // To make compiler happy with unused variable.
  [connection cancel];
  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
  XCTAssertEqual(connection, _capturedPendingObject, @"Unexpected object was blocked.");
}

- (void)testConnectionInitPlusDelegateStartLater {
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:_localHostRequest
                                                                delegate:self
                                                        startImmediately:NO];
  [connection start];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
  XCTAssertEqual(connection, _capturedPendingObject, @"Unexpected object was blocked.");
}

- (void)testConnectionInitPlusDelegateStartNow {
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:_localHostRequest
                                                                delegate:self
                                                        startImmediately:YES];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  // To make compiler happy with unused variable.
  [connection cancel];
  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
  XCTAssertEqual(connection, _capturedPendingObject, @"Unexpected object was blocked.");
}

- (void)testAsyncConnectionClassMethodWithCompletionHandler {
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];

  _connectionFinished = NO;
  [NSURLConnection sendAsynchronousRequest:_localHostRequest
                                     queue:queue
                         completionHandler:^(NSURLResponse *response,
                                             NSData *data,
                                             NSError *connectionError) {
    _connectionFinished = YES;
  }];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
}

- (void)testSyncConnectionClassMethod_mainThread {
  [_mockGREYAppStateTracker stopMocking];
  NSURLResponse *response;
  NSError *error;
  [NSURLConnection sendSynchronousRequest:_localHostRequest
                        returningResponse:&response
                                    error:&error];
  XCTAssertNil(_capturedPendingObject, @"synchronous connections on main thread are not tracked.");
}

- (void)testSyncConnectionClassMethod_backgroundThread {
  __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    NSURLResponse *response;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:_localHostRequest
                          returningResponse:&response
                                      error:&error];
    dispatch_semaphore_signal(semaphore);
  });
  dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (5 * NSEC_PER_SEC));
  dispatch_semaphore_wait(semaphore, timeout);
  [_mockGREYAppStateTracker verify];
}

- (void)testFilterConnectionChanges {
  // All connections should be ignored.
  [[GREYConfiguration sharedInstance] setValue:@[@"."]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURLConnection *connection1 = [[NSURLConnection alloc] initWithRequest:_localHostRequest
                                                                 delegate:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  // To make compiler happy with unused variable.
  [connection1 cancel];

  // All connections should be accepted.
  [[GREYConfiguration sharedInstance] setValue:@[]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  NSURLConnection *connection2 = [[NSURLConnection alloc] initWithRequest:_localHostRequest
                                                                 delegate:self];

  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  // To make compiler happy with unused variable.
  [connection2 cancel];
  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
  XCTAssertEqual(connection2, _capturedPendingObject, @"Unexpected object was blocked.");
}

- (void)testFilterConnectionChangesAfterConnectionStartedButBeforeFinish {
  _connectionFinished = NO;
  NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:_externalRequest
                                                                delegate:self
                                                        startImmediately:NO];

  [connection start];
  // All connections should be ignored.
  [[GREYConfiguration sharedInstance] setValue:@[@"."]
                                  forConfigKey:kGREYConfigKeyURLBlacklistRegex];
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];

  [_mockGREYAppStateTracker verify];
  XCTAssertTrue(_connectionFinished,
                @"We shouldn't have returned until connection has finished.");
}

- (void)testNotTrackedDuringDealloc {
  {
    // NS_VALID_UNTIL_END_OF_SCOPE required so connection is valid until end of the current scope.
    NS_VALID_UNTIL_END_OF_SCOPE NSURLConnectionDealloc *connection =
        [[NSURLConnectionDealloc alloc] init];

    [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
    XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState], kGREYIdle,
                   @"State must be idle so tracking during dealloc can be detected");
  }

  XCTAssertEqual([[GREYAppStateTracker sharedInstance] currentState],
                 kGREYIdle,
                 @"State should be idle after deallocation");
}

- (void)testCreatingNewConnectionIsTracked {
  NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"www.google.com"]];
  NSURLConnection *conn = [NSURLConnection connectionWithRequest:req delegate:nil];
  GREYAppState state =
      [[GREYAppStateTracker sharedInstance] grey_lastKnownStateForObject:conn];
  XCTAssertTrue(state & kGREYPendingNetworkRequest);
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  _connectionFinished = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  _connectionFinished = YES;
}

@end
