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

#import "Action/GREYSwipeAction.h"
#import "GREYBaseTest.h"

@interface GREYSwipeActionTest : GREYBaseTest
@end

@implementation GREYSwipeActionTest

- (void)verifyGREYSwipeActionValidatesStartPercents:(CGPoint)startPercents
                                    forCoordinate:(char)coordinate {
  GREYSwipeAction *swipeAction;
  @try {
    swipeAction = [[GREYSwipeAction alloc] initWithDirection:kGREYDirectionRight
                                                    duration:1.0
                                               startPercents:startPercents];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *expectedErrorDescription =
        [NSString stringWithFormat:@"%cOriginStartPercentage must be between 0 and 1,"
                                   @" exclusively", coordinate];
    XCTAssertEqualObjects(expectedErrorDescription,
                          [exception description],
                          @"Should throw GREYActionFailException");
  }
}

- (void)testInvalidXStartPosition {
  // Test 1.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(1.0f, 0.5f)
                                      forCoordinate:'x'];
  // Test 0.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(0.0f, 0.5f)
                                      forCoordinate:'x'];
  // Test < 0.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(-0.1f, 0.5f)
                                      forCoordinate:'x'];
  // Test > 1.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(1.1f, 0.5f)
                                      forCoordinate:'x'];
}

- (void)testInvalidYStartPosition {
  // Test 1.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(0.5f, 1.0f)
                                      forCoordinate:'y'];
  // Test 0.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(0.5f, 0.0f)
                                      forCoordinate:'y'];
  // Test < 0.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(0.5f, -0.1f)
                                      forCoordinate:'y'];
  // Test > 1.0
  [self verifyGREYSwipeActionValidatesStartPercents:CGPointMake(0.5f, 1.1f)
                                      forCoordinate:'y'];
}

@end
