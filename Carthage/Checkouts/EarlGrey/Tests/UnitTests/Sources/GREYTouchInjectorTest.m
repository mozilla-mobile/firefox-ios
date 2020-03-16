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

#import "Event/GREYTouchInjector.h"
#import "GREYBaseTest.h"

#pragma mark - Methods Only For Testing

@interface GREYTouchInjector (GREYExposedForTesting)
- (GREYTouchInfo *)grey_dequeueTouchInfoForDeliveryWithCurrentTime:(CFTimeInterval)currentTime;
@end

@interface GREYTouchInjectorTest : GREYBaseTest
@end

@implementation GREYTouchInjectorTest {
  GREYTouchInjector *_injector;
}

- (void)setUp {
  [super setUp];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectZero];
  _injector = [[GREYTouchInjector alloc] initWithWindow:window];
}

- (GREYTouchInfo *)touchInfoWithTimeDelta:(CFTimeInterval)delta
                             expendable:(BOOL)expendable {
  return [[GREYTouchInfo alloc] initWithPoints:@[[NSValue valueWithCGPoint:CGPointZero]]
                                         phase:GREYTouchInfoPhaseTouchBegan
               deliveryTimeDeltaSinceLastTouch:delta
                                    expendable:expendable];
}

- (void)testTouchInjectoreCanDequeueSingleNonExpendableTouchInQueue {
  GREYTouchInfo *touch = [self touchInfoWithTimeDelta:0 expendable:NO];
  [_injector enqueueTouchInfoForDelivery:touch];
  XCTAssertEqual([_injector grey_dequeueTouchInfoForDeliveryWithCurrentTime:0],
                 touch);
}

- (void)testTouchInjectoreCanDequeueMultipleNonExpendableTouchesInQueue {
  GREYTouchInfo *touch1 = [self touchInfoWithTimeDelta:0 expendable:NO];
  GREYTouchInfo *touch2 = [self touchInfoWithTimeDelta:1 expendable:NO];
  [_injector enqueueTouchInfoForDelivery:touch1];
  [_injector enqueueTouchInfoForDelivery:touch2];
  XCTAssertEqual([_injector grey_dequeueTouchInfoForDeliveryWithCurrentTime:0],
                 touch1);
  XCTAssertEqual([_injector grey_dequeueTouchInfoForDeliveryWithCurrentTime:1],
                 touch2);
}

- (void)testTouchInjectoreCanDequeueSingleExpendableTouchInQueue {
  GREYTouchInfo *touch = [self touchInfoWithTimeDelta:0 expendable:YES];
  [_injector enqueueTouchInfoForDelivery:touch];
  XCTAssertEqual([_injector grey_dequeueTouchInfoForDeliveryWithCurrentTime:1],
                 touch);
}

- (void)testTouchInjectoreCanDequeueMultipleExpendableTouchesInQueue {
  GREYTouchInfo *touch1 = [self touchInfoWithTimeDelta:0 expendable:YES];
  GREYTouchInfo *touch2 = [self touchInfoWithTimeDelta:1 expendable:YES];
  [_injector enqueueTouchInfoForDelivery:touch1];
  [_injector enqueueTouchInfoForDelivery:touch2];

  // At time=2 both touch1 and touch2 are stale therefore _injector must drop touch1 and dequeue
  // the least stale touch - touch2.
  XCTAssertEqual([_injector grey_dequeueTouchInfoForDeliveryWithCurrentTime:2],
                 touch2);
  // Queue must be empty now.
  XCTAssertEqual([_injector grey_dequeueTouchInfoForDeliveryWithCurrentTime:2],
                 nil);
}

@end
