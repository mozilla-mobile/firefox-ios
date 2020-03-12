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

#import <EarlGrey/GREYSyncAPI.h>
#import <EarlGrey/GREYUIThreadExecutor.h>
#import "GREYBaseTest.h"

@interface GREYSyncAPITest : GREYBaseTest

@end

@implementation GREYSyncAPITest

- (void)testExecuteAsync {
  __block BOOL executed = NO;
  grey_execute_async(^{
    executed = YES;
  });
  [[GREYUIThreadExecutor sharedInstance] drainUntilIdle];
  XCTAssertTrue(executed);
}

- (void)testExecuteSync {
  __block BOOL executed = NO;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    grey_execute_sync(^{
      executed = YES;
    });
  });
  GREYCondition *blockExecuted = [GREYCondition conditionWithName:@"waitForSyncExecution"
                                                            block:^BOOL{
    return executed;
  }];
  BOOL success = [blockExecuted waitWithTimeout:5.0];
  XCTAssertTrue(success);
}

@end
