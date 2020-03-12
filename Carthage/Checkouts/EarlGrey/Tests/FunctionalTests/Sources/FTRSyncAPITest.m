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
#import "Additions/UIApplication+GREYAdditions.h"
#import "Common/GREYAppleInternals.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRSyncAPITest : FTRBaseIntegrationTest

@end

@implementation FTRSyncAPITest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Basic Views"];
}

- (void)testPushAndPopRunLoopModes {
  GREYAssertNil([[UIApplication sharedApplication] grey_activeRunLoopMode], @"should be nil");
  [[UIApplication sharedApplication] pushRunLoopMode:@"Boo" requester:self];
  GREYAssertEqualObjects([[UIApplication sharedApplication] grey_activeRunLoopMode], @"Boo",
                         @"should be equal");
  [[UIApplication sharedApplication] pushRunLoopMode:@"Foo"];
  GREYAssertEqualObjects([[UIApplication sharedApplication] grey_activeRunLoopMode], @"Foo",
                         @"should be equal");
  [[UIApplication sharedApplication] popRunLoopMode:@"Foo"];
  GREYAssertEqualObjects([[UIApplication sharedApplication] grey_activeRunLoopMode], @"Boo",
                         @"should be equal");
  [[UIApplication sharedApplication] popRunLoopMode:@"Boo" requester:self];
  GREYAssertNotEqualObjects([[UIApplication sharedApplication] grey_activeRunLoopMode], @"Boo",
                            @"should not be equal");
  GREYAssertNotEqualObjects([[UIApplication sharedApplication] grey_activeRunLoopMode], @"Foo",
                            @"should not be equal");
}

- (void)testGREYExecuteSync {
  __block BOOL firstGREYExecuteSyncStarted = NO;
  __block BOOL secondGREYExecuteSyncStarted = NO;

  // Execute on a background thread.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // To synchronize execution on background thread, grey_execute_sync must be called.
    grey_execute_sync(^{
      firstGREYExecuteSyncStarted = YES;
      [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
          performAction:grey_tap()];
      id<GREYMatcher> matcher = grey_allOf(grey_kindOfClass([UITextField class]),
                                           grey_accessibilityLabel(@"Type Something Here"),
                                           nil);
      [[[EarlGrey selectElementWithMatcher:matcher] performAction:grey_tap()]
          performAction:grey_typeText(@"Hello!")];
    });
    grey_execute_sync(^{
      secondGREYExecuteSyncStarted = YES;
      id<GREYMatcher> matcher = grey_allOf(grey_kindOfClass([UITextField class]),
                                           grey_accessibilityLabel(@"Type Something Here"),
                                           nil);
      [[EarlGrey selectElementWithMatcher:matcher] assertWithMatcher:grey_text(@"Hello!")];
    });
  });

  // This should wait for the first grey_execute_sync to start execution on the background thread.
  // It's possible that the last condition check before the timeout will occur at the beginning of
  // the run loop drain where the execute sync block runs. The run loop spinner will not start more
  // run loop drains after the timeout. So the timeout must be large enough to allow the entire
  // execute sync block to run in order to guarantee that we will check the condition after the
  // execute sync block has run.
  BOOL success = [[GREYCondition conditionWithName:@"Wait for first grey_execute_sync"
                                             block:^BOOL{
    return firstGREYExecuteSyncStarted;
  }] waitWithTimeout:20.0];
  GREYAssert(success, @"Waiting for first grey_execute_sync to start timed-out");

  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITextField class]),
                                                 grey_accessibilityLabel(@"Type Something Here"),
                                                 nil)]
      assertWithMatcher:grey_text(@"Hello!")];

  // This should wait for the second grey_execute_sync to start execution on the background thread.
  success = [[GREYCondition conditionWithName:@"Wait for first grey_execute_sync"
                                        block:^BOOL{
    return secondGREYExecuteSyncStarted;
  }] waitWithTimeout:5.0];
  GREYAssert(success, @"Waiting for second grey_execute_sync to start timed-out");
}

- (void)testGREYExecuteAsyncOnMainThread {
  grey_execute_async(^{
    [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
        performAction:grey_tap()];
    [[[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITextField class]),
                                                    grey_accessibilityLabel(@"Type Something Here"),
                                                    nil)]
        performAction:grey_tapAtPoint(CGPointMake(0, 0))]
        performAction:grey_typeText(@"Hello!")];
  });
  // This should wait for the above async task to finish.
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITextField class]),
                                                 grey_accessibilityLabel(@"Type Something Here"),
                                                 nil)]
      assertWithMatcher:grey_text(@"Hello!")];
}

- (void)testGREYExecuteAsyncOnBackgroundThread {
  __block BOOL executeAsyncStarted = NO;

  // Execute on a background thread.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    grey_execute_async(^{
      executeAsyncStarted = YES;
      [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
          performAction:grey_tap()];
      id matcher = grey_allOf(grey_kindOfClass([UITextField class]),
                              grey_accessibilityLabel(@"Type Something Here"),
                              nil);
      [[[EarlGrey selectElementWithMatcher:matcher] performAction:grey_tap()]
          performAction:grey_typeText(@"Hello!")];
    });
  });
  // This should wait for the first grey_execute_sync to start execution on the background thread.
  // It's possible that the last condition check before the timeout will occur at the beginning of
  // the run loop drain where the execute sync block runs. The run loop spinner will not start more
  // run loop drains after the timeout. So the timeout must be large enough to allow the entire
  // execute sync block to run in order to guarantee that we will check the condition after the
  // execute sync block has run.
  BOOL success = [[GREYCondition conditionWithName:@"Wait for background grey_execute_async"
                                             block:^BOOL{
    return executeAsyncStarted;
  }] waitWithTimeout:20.0];
  GREYAssert(success, @"Waiting for grey_execute_async to start timed-out");

  // This should wait for the above async to finish.
  [[EarlGrey selectElementWithMatcher:grey_allOf(grey_kindOfClass([UITextField class]),
                                                 grey_accessibilityLabel(@"Type Something Here"),
                                                 nil)]
      assertWithMatcher:grey_text(@"Hello!")];
}

@end
