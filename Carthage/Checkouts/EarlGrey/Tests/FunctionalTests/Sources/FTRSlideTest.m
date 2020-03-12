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
#import <EarlGrey/EarlGrey.h>

@interface FTRSlideTest : FTRBaseIntegrationTest

@end

@implementation FTRSlideTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Slider Views"];
}

- (void)testSlider1SlidesCloseToZero {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider1")]
      performAction:grey_moveSliderToValue(0.125f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(0.125f,
                                                             kGREYAcceptableFloatDifference))];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider1")]
      performAction:grey_moveSliderToValue(0.0f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(0.0f, 0))];
}

- (void)testSlider2SlidesToValue {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider2")]
      performAction:grey_moveSliderToValue(15.74f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(15.74f,
                                                             kGREYAcceptableFloatDifference))];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider2")]
      performAction:grey_moveSliderToValue(21.03f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(21.03f,
                                                             kGREYAcceptableFloatDifference))];
}

- (void)testSlider3SlidesToClosestValue {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider3")]
      performAction:grey_moveSliderToValue(0.0f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(0, 0))];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider3")]
      performAction:grey_moveSliderToValue(900.0f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(900.0f,
                                                             kGREYAcceptableFloatDifference))];
}

- (void)testSlider4IsExactlyValue {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider4")]
      performAction:grey_moveSliderToValue(500000.0f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(500000.0f,
                                                             kGREYAcceptableFloatDifference))];
}

- (void)testSlider5SnapsToValueWithSnapOnTouchUp {
  // For sliders that "stick" (have tick marks) to certain values, the tester must calculate the
  // tick value that will result by setting the slider to an arbitrary value.
  // See FTRSliderViewController.m for details on how my slider's tick values were calculated.
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider5")]
      performAction:grey_moveSliderToValue(60.0f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(60.3f,
                                                             kGREYAcceptableFloatDifference))];
}

- (void)testSlider6SnapsToValueWithContinuousSnapping {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider6")]
      performAction:grey_moveSliderToValue(37.5f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(50.0f,
                                                             kGREYAcceptableFloatDifference))];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"slider6")]
      performAction:grey_moveSliderToValue(62.5f)]
      assertWithMatcher:grey_sliderValueMatcher(grey_closeTo(50.0f,
                                                             kGREYAcceptableFloatDifference))];
}

- (void)testSmallSliderSnapsToAllValues {
  for (int i = 0; i <= 10; i++) {
    id<GREYMatcher> closeToMatcher = grey_closeTo((double)i, kGREYAcceptableFloatDifference);
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sliderSnap")]
        performAction:grey_moveSliderToValue((float)i)]
        assertWithMatcher:grey_sliderValueMatcher(closeToMatcher)];
  }
}

@end
