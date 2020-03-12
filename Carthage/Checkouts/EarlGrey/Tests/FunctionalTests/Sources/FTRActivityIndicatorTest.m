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

@interface FTRActivityIndicatorViewTest : FTRBaseIntegrationTest
@end

@implementation FTRActivityIndicatorViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Activity Indicator Views"];
}

- (void)testSynchronizationWithStartAndStop {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"StartStop")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Status")]
      assertWithMatcher:grey_text(@"Stopped")];
}

- (void)testSynchronizationWithStartAndHide {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"StartHide")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Status")]
      assertWithMatcher:grey_text(@"Hidden")];
}

- (void)testSynchronizationWithStartAndHideWithoutHidesWhenStopped {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"HidesWhenStopped")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"StartHide")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Status")]
      assertWithMatcher:grey_text(@"Hidden")];
}

- (void)testSynchronizationWithStartAndRemoveFromSuperview {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"StartRemove")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Status")]
      assertWithMatcher:grey_text(@"Removed from superview")];
}

- (void)testSynchronizationWithHideAndStartThenStop {
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"HideStartStop")] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Status")]
      assertWithMatcher:grey_text(@"Stopped")];
}

@end
