//
// Copyright 2017 Google Inc.
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

#import <XCTest/XCTest.h>

#import <EarlGrey/GREYAssertionDefines.h>
#import "Synchronization/GREYAppStateTracker.h"
#import <EarlGrey/GREYFailureHandler.h>
#import <EarlGrey/EarlGreyImpl.h>

// Failure handler for EarlGrey unit tests
@interface GREYAssertionFailureHandler : NSObject<GREYFailureHandler>
@property(nonatomic, strong) GREYFrameworkException *exception;
@end

// Failure handler for EarlGrey unit tests
@implementation GREYAssertionFailureHandler

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  self.exception = exception;
}

@end

@interface GREYAssertionDefinesTest : XCTestCase

@end

@implementation GREYAssertionDefinesTest

- (void)testAssertionTimedOut {
  // Set a failure handler.
  GREYAssertionFailureHandler *handler = [[GREYAssertionFailureHandler alloc] init];
  [EarlGrey setFailureHandler:handler];

  // Make the app not idle.
  NSObject *object = [[NSObject alloc] init];
  [[GREYAppStateTracker sharedInstance] trackState:kGREYPendingViewsToAppear forObject:object];

  // Change timeout
  [[GREYConfiguration sharedInstance] setValue:@1
                                  forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];
  GREYAssertTrue(1, @"This should be true.");

  // Get the exception object.
  GREYFrameworkException *exception = [handler exception];
  XCTAssertEqual([exception name], kGREYTimeoutException);
  NSUInteger location =
      [exception.reason rangeOfString:@"Couldn't assert that (1) is true."].location;
  XCTAssertNotEqual(location, NSNotFound);
}


@end
