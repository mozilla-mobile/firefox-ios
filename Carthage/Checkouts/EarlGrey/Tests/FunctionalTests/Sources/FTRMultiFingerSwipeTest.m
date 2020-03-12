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

#import "FTRBaseIntegrationTest.h"
#import <EarlGrey/EarlGrey.h>

@interface FTRMultiFingerSwipeTest : FTRBaseIntegrationTest
@end

@implementation FTRMultiFingerSwipeTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Multi finger swipe gestures"];
}

#pragma mark - Two fingers

- (void)testTwoFingerSwipeLeft {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionLeft, 2)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Left")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testTwoFingerSwipeRight {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionRight, 2)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Right")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testTwoFingerSwipeUp {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionUp, 2)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Up")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testTwoFingerSwipeDown {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionDown, 2)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 2 fingers Down")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

#pragma mark - Three fingers

- (void)testThreeFingerSwipeLeft {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionLeft, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Left")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testThreeFingerSwipeRight {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
   performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionRight, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Right")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testThreeFingerSwipeUp {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionUp, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Up")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testThreeFingerSwipeDown {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionDown, 3)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 3 fingers Down")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

#pragma mark - Four fingers

- (void)testFourFingerSwipeLeft {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionLeft, 4)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Left")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testFourFingerSwipeRight {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionRight, 4)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Right")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testFourFingerSwipeUp {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionUp, 4)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Up")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testFourFingerSwipeDown {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"gestureRecognizerBox")]
      performAction:grey_multiFingerSwipeFastInDirection(kGREYDirectionDown, 4)];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Swiped with 4 fingers Down")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

@end
