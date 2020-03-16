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

#import "Action/GREYScrollAction.h"
#import "GREYBaseTest.h"

@interface GREYScrollActionTest : GREYBaseTest
@end

@implementation GREYScrollActionTest

- (void)testGREYScrollerFailsToCreateWithInvalidScrollAmounts {
  [self verifyGREYScrollActionInitFailsWithAmount:0.0];
  [self verifyGREYScrollActionInitFailsWithAmount:-1.0];
}

- (void)testGREYScrollerCanInitWithValidStartPointsPercents {
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0.001f, 0.001f) fails:NO];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0.001f, 0.99f) fails:NO];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0.99f, 0.99f) fails:NO];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0.99f, 0.001f) fails:NO];
}

- (void)testGREYScrollerFailsToCreateWithInvalidStartPointsPercents {
  // Start point percents must be in (0, 1) exclusive or must be NAN.
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0, 0) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0, 0) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(NAN, 0) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0, NAN) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0, 0) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(1, 0.1f) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(0.1f, 1) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(1, 1) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(NAN, 1) fails:YES];
  [self verifyScrollActionInitWithStartPoint:CGPointMake(1, NAN) fails:YES];
}

#pragma mark - Private Methods

- (void)verifyGREYScrollActionInitFailsWithAmount:(CGFloat)amount {
  GREYScrollAction *scrollAction;
  @try {
    scrollAction = [[GREYScrollAction alloc] initWithDirection:kGREYDirectionUp amount:amount];
    XCTFail(@"Should have thrown an exception for scroll amount %f", (float)amount);
  } @catch (NSException *exception) {
    XCTAssertEqualObjects(@"Scroll amount must be positive and greater than zero.",
                          [exception description],
                          @"Should throw NSInternalInconsistencyException");
  }
}

- (void)verifyScrollActionInitWithStartPoint:(CGPoint)startPoint fails:(BOOL)fails {
  GREYScrollAction *scrollAction;
  @try {
    scrollAction = [[GREYScrollAction alloc] initWithDirection:kGREYDirectionUp
                                                        amount:100
                                            startPointPercents:startPoint];
    if (fails) {
      XCTFail(@"Should have thrown an exception for scroll point %@",
              NSStringFromCGPoint(startPoint));
    } else {
      XCTAssertNotNil(scrollAction);
    }
  } @catch (NSException *exception) {
    XCTAssertEqualObjects(@"startPointPercents must be NAN or in the range (0, 1) exclusive",
                          [exception description],
                          @"Should throw NSInternalInconsistencyException");
  }
}

@end
