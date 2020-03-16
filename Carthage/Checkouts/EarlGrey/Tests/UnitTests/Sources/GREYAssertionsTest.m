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

#import <OCMock.h>

#import <EarlGrey/GREYAssertion.h>
#import "Assertion/GREYAssertions+Internal.h"
#import <EarlGrey/GREYAssertions.h>
#import <EarlGrey/GREYElementFinder.h>
#import <EarlGrey/GREYMatchers.h>
#import "GREYBaseTest.h"

static NSMutableArray *gAppWindows;

@interface GREYAssertionsTest : GREYBaseTest
@end

@implementation GREYAssertionsTest

- (void)setUp {
  [super setUp];
  gAppWindows = [[NSMutableArray alloc] init];
  [[[self.mockSharedApplication stub] andReturn:gAppWindows] windows];
}

- (void)testViewHasTextWithEmptyString {
  UIView *view = [[UIView alloc] init];
  NSError *error;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(@"")] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testViewHasTextWithNilOrNotSubclass {
  UIView *view = [[UIView alloc] init];
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(@"txt")] assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);

  error = nil;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(@"txt")] assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testMatchesThrowsExceptionForNilView {
  NSError *error;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(@"")] assert:nil error:&error];

  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testViewHasTextWithText {
  NSString *textToFind = @"A String";
  NSError *error;

  UILabel *label = [[UILabel alloc] init];
  label.text = textToFind;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(textToFind)] assert:label
                                                                           error:&error];
  XCTAssertNil(error);
  error = nil;

  UITextField *textField = [[UITextField alloc] init];
  textField.text = textToFind;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(textToFind)] assert:textField
                                                                           error:&error];
  XCTAssertNil(error);
  error = nil;

  UITextView *textView = [[UITextView alloc] init];
  textView.text = textToFind;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(textToFind)] assert:textView
                                                                           error:nil];
  XCTAssertNil(error);
}

- (void)testViewHasTextWithWrongText {
  NSString *textToFind = @"A String";
  NSError *error;

  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(textToFind)] assert:label
                                                                           error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);

  UITextField *textField= [[UITextField alloc] init];
  textField.text = @"";
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(textToFind)] assert:textField
                                                                           error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);

  UITextView *textView = [[UITextView alloc] init];
  textView.text = @"A Different String";
  [[GREYAssertions grey_createAssertionWithMatcher:grey_text(textToFind)] assert:textView
                                                                           error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithNil {
  NSError *error;
  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:nil
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testIsVisibleWithHalfAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.5f;
  view.hidden = YES;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = YES;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithoutAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithoutAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = YES;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithLessThanMinimumVisibleAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.009f;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithZeroWidth {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
  view.alpha = 1;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithZeroHeight {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
  view.alpha = 1;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsVisibleWithZeroWidthAndHeight {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  view.alpha = 1;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_sufficientlyVisible()] assert:view
                                                                                error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testIsNotVisibleWithAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 1;
  view.hidden = YES;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_notVisible()] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithLessThanMinimumVisibleAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.009f;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_notVisible()] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithHalfAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.009f;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_notVisible()] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithHalfAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0.5f;
  view.hidden = YES;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_notVisible()] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithoutAlphaAndNotHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = NO;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_notVisible()] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testIsNotVisibleWithoutAlphaAndHidden {
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  view.alpha = 0;
  view.hidden = YES;
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_notVisible()] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testAllOfMatcherWithNil {
  UIView *view = [[UIView alloc] init];
  NSError *error;

  id<GREYAssertion> assertion =
      [GREYAssertions grey_createAssertionWithMatcher:grey_allOf(grey_equalTo(view), grey_notNil(),
                                                                 nil)];
  [assertion assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testAllOfMatcherWithView {
  UIView *view = [[UIView alloc] init];
  id<GREYMatcher> allOfMatcher = grey_allOf(grey_equalTo(view), grey_notNil(), nil);
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:allOfMatcher] assert:view error:&error];
  XCTAssertNil(error);
}

- (void)testAssertionForIsNilMatcherWithNil {
  NSError *error;

  [[GREYAssertions grey_createAssertionWithMatcher:grey_nil()] assert:nil error:&error];
  XCTAssertNil(error);
}

- (void)testAssertionForIsNilMatcherWithView {
  NSError *error;

  UIView *view = [[UIView alloc] init];
  id<GREYAssertion> assertion = [GREYAssertions grey_createAssertionWithMatcher:grey_nil()];
  [assertion assert:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionAssertionFailedErrorCode);
}

- (void)testAssertionForIsNotNilMatcherWithNil {
  NSError *error;

  id<GREYAssertion> assertion = [GREYAssertions grey_createAssertionWithMatcher:grey_notNil()];
  [assertion assert:nil error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
}

- (void)testAssertionForIsNotNilMatcherWithView {
  NSError *error;
  UIView *view = [[UIView alloc] init];
  [[GREYAssertions grey_createAssertionWithMatcher:grey_notNil()] assert:view error:&error];
  XCTAssertNil(error);
}

@end
