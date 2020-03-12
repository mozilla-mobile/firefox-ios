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

@interface FTRAlertViewTest : FTRBaseIntegrationTest
@end

@implementation FTRAlertViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Alert Views"];
}

- (void)testSimpleAlertView {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Simple Alert")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Flee")] performAction:[GREYActions actionForTap]];
}

- (void)testMultiOptionAlertView {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Multi-Option Alert")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Use Slingshot")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Multi-Option Alert")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Use Phaser")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Roger")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Multi-Option Alert")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testAlertViewChain {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Multi-Option Alert")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Use Phaser")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Roger")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Multi-Option Alert")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testStyledAlertView {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Styled Alert")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Login")]
      performAction:grey_typeText(@"test_user")];
  [[EarlGrey selectElementWithMatcher:grey_text(@"test_user")] assertWithMatcher:grey_notNil()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Password")]
      performAction:grey_typeText(@"test_pwd")];
  [[EarlGrey selectElementWithMatcher:grey_text(@"test_pwd")] assertWithMatcher:grey_notNil()];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Leave")]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:grey_text(@"Roger")]
      performAction:[GREYActions actionForTap]];
}

@end
