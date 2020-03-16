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
#import "FTRFailureHandler.h"

#import "Common/GREYError.h"
#import "Common/GREYErrorConstants.h"

@interface FTRErrorAPITest : FTRBaseIntegrationTest
@end

@implementation FTRErrorAPITest {
  id<GREYMatcher> _matcherForNonExistingTab;
}

+ (void)setUp {
  @try {
    GREYFail(@"Testing if this raises an exception and fails the suite");
    assert(NULL);
  } @catch (id expectedException) {
    if (![expectedException isKindOfClass:[GREYFrameworkException class]]) {
      NSLog(@"Incorrect exception class: %@ raised.", [expectedException class]);
      @throw;
    }
  }
}

- (void)setUp {
  [super setUp];

  [self openTestViewNamed:@"Basic Views"];
  _matcherForNonExistingTab = grey_text(@"Tab That Does Not Exist");
}

- (void)testCallAllAssertionDefines {
  GREYAssert(42, @"42 should assert fine.");
  GREYAssertTrue(1 == 1, @"1 should be equal to 1");
  GREYAssertFalse(0 == 1, @"0 shouldn't be equal to 1");
  GREYAssertEqual(1, 1, @"1 should be equal to 1");
  GREYAssertNotEqual(1, 2, @"1 should not be equal to 2");
  GREYAssertEqualObjects(@"foo", [[NSString alloc] initWithFormat:@"foo"],
                         @"strings foo must be equal");
  GREYAssertNotEqualObjects(@"foo", @"bar", @"string foo and bar must not be equal");
  GREYAssertNil(nil, @"nil should be nil");
  GREYAssertNotNil([[NSObject alloc] init], @"a valid object should not be nil");
}

- (void)testAssertionErrorAPI {
  NSError *error;

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap() error:&error];
  GREYAssertNil(error, @"Must be nil");

  [[EarlGrey selectElementWithMatcher:_matcherForNonExistingTab]
      assertWithMatcher:grey_nil() error:&error];
  GREYAssertTrue(error.code == kGREYInteractionElementNotFoundErrorCode,
                 @"The error code should point to element not found");

  [[EarlGrey selectElementWithMatcher:_matcherForNonExistingTab]
      assertWithMatcher:grey_notNil() error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"domain should match");
  GREYAssertTrue(error.code == kGREYInteractionElementNotFoundErrorCode, @"code should match");
  GREYError *greyError = (GREYError *)error;
  GREYAssertTrue([greyError.errorInfo[kErrorDetailElementMatcherKey]
                 isEqualToString:_matcherForNonExistingTab.description],
                 @"description should match");
  GREYAssertEqualObjects(greyError.errorInfo[kErrorDetailElementMatcherKey],
                         _matcherForNonExistingTab.description, @"description should match");

  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")]
      assertWithMatcher:grey_nil() error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"domain should match");
  GREYAssertTrue(error.code == kGREYInteractionAssertionFailedErrorCode, @"code should match");

  [EarlGrey setFailureHandler:[[FTRFailureHandler alloc] init]];
  // Should throw exception.
  @try {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")]
        assertWithMatcher:grey_nil() error:nil];
    GREYFail(@"Shouldn't be here");
  } @catch (GREYFrameworkException *exception) {
    GREYAssertTrue([exception.name isEqual:@"AssertionFailedException"],
                 @"exception name didn't match");
  }
}

- (void)testActionErrorAPI {
  NSError *error;

  // Element not found.
  [[EarlGrey selectElementWithMatcher:_matcherForNonExistingTab] performAction:grey_tap()
                                                                         error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"domain should match");
  GREYAssertTrue(error.code == kGREYInteractionElementNotFoundErrorCode, @"code should match");
  GREYError *greyError = (GREYError *)error;
  GREYAssertEqualObjects(greyError.errorInfo[kErrorDetailElementMatcherKey],
                         _matcherForNonExistingTab.description, @"description should match");

  // grey_type on a Tab should cause action constraints to fail.
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_typeText(@"")
                                                                   error:&error];
  GREYAssertTrue([error.domain isEqualToString:kGREYInteractionErrorDomain],
                 @"domain should match");
  GREYAssertTrue(error.code == kGREYInteractionActionFailedErrorCode, @"code should match");

  [EarlGrey setFailureHandler:[[FTRFailureHandler alloc] init]];
  // Should throw exception.
  @try {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_typeText(@"")
                                                                     error:nil];
    GREYFail(@"Shouldn't be here");
  } @catch (GREYFrameworkException *exception) {
    GREYAssertTrue([exception.name isEqual:@"ActionFailedException"],
                   @"exception name didn't match");
  }
}

@end
