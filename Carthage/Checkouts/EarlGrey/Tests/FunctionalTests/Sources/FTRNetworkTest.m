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

#import "FTRBaseIntegrationTest.h"
#import "FTRNetworkProxy.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRNetworkTest : FTRBaseIntegrationTest
@end

@implementation FTRNetworkTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Network Test"];
}

- (void)testSynchronizationWorksWithNSURLConnection {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_notVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NSURLConnectionTest")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRResponseVerifiedLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSynchronizationWithNSURLSessionCompletionHandlers {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_notVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NSURLSessionTest")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRResponseVerifiedLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSynchronizationWorksWithNSURLSessionDelegates {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_notVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NSURLSessionDelegateTest")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRResponseVerifiedLabel")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testSynchronizationWorksWithoutNetworkCallbacks {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRRequestCompletedLabel")]
      assertWithMatcher:grey_notVisible()];
  // Make the network requests to take longer.
  [FTRNetworkProxy ftr_setSimulatedNetworkDelay:1.0];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NSURLSessionNoCallbackTest")]
      performAction:grey_tap()];
  NSTimeInterval startTime = CACurrentMediaTime();
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  // Verify that EarlGrey did not wait for the request.
  GREYAssert(CACurrentMediaTime() - startTime < 1.0,
             @"EarlGrey must not wait for the network request");
  [FTRNetworkProxy ftr_setSimulatedNetworkDelay:0.0];
}

@end
