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

#import "Synchronization/GREYTimedIdlingResource.h"
#import "GREYBaseTest.h"

@interface GREYTimedIdlingResourceTest : GREYBaseTest

@end

@implementation GREYTimedIdlingResourceTest

- (void)testNoCompletion {
  NSObject *obj1 = [[NSObject alloc] init];
  NSObject *obj2 = [[NSObject alloc] init];

  GREYTimedIdlingResource *res1 = [GREYTimedIdlingResource resourceForObject:obj1
                                                       thatIsBusyForDuration:1.0
                                                                        name:@"test1"];
  GREYTimedIdlingResource *res2 = [GREYTimedIdlingResource resourceForObject:obj2
                                                       thatIsBusyForDuration:2.0
                                                                        name:@"test2"];

  XCTAssertFalse([res1 isIdleNow]);
  XCTAssertFalse([res2 isIdleNow]);

  [NSThread sleepForTimeInterval:0.1];

  XCTAssertFalse([res1 isIdleNow]);
  XCTAssertFalse([res2 isIdleNow]);

  [res1 stopMonitoring];
  [res2 stopMonitoring];

  XCTAssertTrue([res1 isIdleNow]);
  XCTAssertTrue([res2 isIdleNow]);
}

- (void)testTerminateOneAfterOther {
  NSObject *obj1 = [[NSObject alloc] init];
  NSObject *obj2 = [[NSObject alloc] init];

  GREYTimedIdlingResource *res1 = [GREYTimedIdlingResource resourceForObject:obj1
                                                       thatIsBusyForDuration:0.1
                                                                        name:@"test1"];
  GREYTimedIdlingResource *res2 = [GREYTimedIdlingResource resourceForObject:obj2
                                                       thatIsBusyForDuration:0.3
                                                                        name:@"test2"];

  [NSThread sleepForTimeInterval:0.1];

  XCTAssertTrue([res1 isIdleNow]);
  XCTAssertFalse([res2 isIdleNow]);

  [NSThread sleepForTimeInterval:0.3];

  XCTAssertTrue([res2 isIdleNow]);
}

- (void)testTerminateBothTogether {
  NSObject *obj1 = [[NSObject alloc] init];
  NSObject *obj2 = [[NSObject alloc] init];

  GREYTimedIdlingResource *res1 = [GREYTimedIdlingResource resourceForObject:obj1
                                                       thatIsBusyForDuration:0.1
                                                                        name:@"test1"];
  GREYTimedIdlingResource *res2 = [GREYTimedIdlingResource resourceForObject:obj2
                                                       thatIsBusyForDuration:0.1
                                                                        name:@"test2"];

  [NSThread sleepForTimeInterval:0.1];

  XCTAssertTrue([res1 isIdleNow]);
  XCTAssertTrue([res2 isIdleNow]);
}

@end
