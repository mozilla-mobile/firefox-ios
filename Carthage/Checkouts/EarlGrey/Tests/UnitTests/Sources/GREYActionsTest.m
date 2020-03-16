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

#import <EarlGrey/GREYActions.h>
#import "Additions/NSObject+GREYAdditions.h"
#import <EarlGrey/GREYConstants.h>
#import "Common/GREYError.h"
#import <EarlGrey/GREYElementMatcherBlock.h>
#import <EarlGrey/GREYMatchers.h>
#import "GREYBaseTest.h"

@interface GREYActionsTest : GREYBaseTest
@end

@implementation GREYActionsTest

- (void)testTapActionConstraintsFailed {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> tap = [GREYActions actionForTap];
  @try {
    [tap perform:view error:nil];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *reason = @"Cannot perform action due to constraint(s) failure.";
    XCTAssertEqualObjects([exception name], kGREYActionFailedException,
                          @"Should throw GREYActionFailException");
    NSRange reasonRange = [exception.reason rangeOfString:reason];
    XCTAssertNotEqual(reasonRange.location, NSNotFound,
                      @"Did we change the exception reason?");
    NSRange viewDescriptionRange = [exception.reason rangeOfString:[view grey_description]];
    XCTAssertNotEqual(viewDescriptionRange.location, NSNotFound,
                      @"Did we change the element description?");
  }
}

- (void)testTapActionConstraintsFailedWithNSError {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> tap = [GREYActions actionForTap];
  GREYError *error;
  [tap perform:view error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"Wrong error domain.");
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode,
                 @"Wrong error code.");
  XCTAssertEqualObjects(error.errorInfo[kErrorDetailActionNameKey], @"Tap",
                        @"Wrong error action.");
  XCTAssertEqualObjects(error.errorInfo[@"Element Description"], [view grey_description],
                        @"Wrong error element description.");
}

- (void)testMultiTapActionConstraintsFailed {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> doubleTap = [GREYActions actionForMultipleTapsWithCount:2];
  @try {
    [doubleTap perform:view error:nil];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *actionName = @"Tap 2 times";
    XCTAssertEqualObjects([exception name], kGREYActionFailedException,
                          @"Should throw GREYActionFailException");
    NSRange actionNameRange = [exception.reason rangeOfString:actionName];
    XCTAssertNotEqual(actionNameRange.location, NSNotFound,
                      @"Did we change the action name?");
    NSRange viewDescriptionRange = [exception.reason rangeOfString:[view grey_description]];
    XCTAssertNotEqual(viewDescriptionRange.location, NSNotFound,
                      @"Did we change the element description?");

  }
}

- (void)testMultiTapActionWithZeroTapCount {
  XCTAssertThrowsSpecificNamed([GREYActions actionForMultipleTapsWithCount:0],
                               NSException,
                               NSInternalInconsistencyException,
                               @"Should throw an exception for initializing a tap action with "
                               @"zero tap count.");
}

- (void)testTurnSwitchActionConstraintsFailed {
  UISwitch *uiswitch = [[UISwitch alloc] init];
  uiswitch.hidden = YES;
  id<GREYAction> turnSwitch = grey_turnSwitchOn(YES);
  @try {
    [turnSwitch perform:uiswitch error:nil];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *reason = @"Cannot perform action due to constraint(s) failure.";
    NSString *actionName = @"Long Press for 0.700000 seconds";
    XCTAssertEqualObjects([exception name], kGREYActionFailedException,
                          @"Should throw GREYActionFailException");
    NSRange reasonRange = [exception.reason rangeOfString:reason];
    XCTAssertNotEqual(reasonRange.location, NSNotFound,
                      @"Did we change the exception reason?");
    NSRange actionNameRange = [exception.reason rangeOfString:actionName];
    XCTAssertNotEqual(actionNameRange.location, NSNotFound,
                      @"Did we change the action name?");
    NSRange viewDescriptionRange = [exception.reason rangeOfString:[uiswitch grey_description]];
    XCTAssertNotEqual(viewDescriptionRange.location, NSNotFound,
                      @"Did we change the element description?");
  }
}

- (void)testSwipeLeftActionConstraintsFailed {
  UIView *view = [[UIView alloc] init];
  id<GREYAction> swipeLeft = [GREYActions actionForSwipeFastInDirection:kGREYDirectionLeft];
  @try {
    [swipeLeft perform:view error:nil];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *reason = @"Cannot perform action due to constraint(s) failure.";
    NSString *actionName = @"Swipe Left for duration 0.1";
    XCTAssertEqualObjects([exception name], kGREYActionFailedException,
                          @"Should throw GREYActionFailException");
    NSRange reasonRange = [exception.reason rangeOfString:reason];
    XCTAssertNotEqual(reasonRange.location, NSNotFound,
                      @"Did we change the exception reason?");
    NSRange actionNameRange = [exception.reason rangeOfString:actionName];
    XCTAssertNotEqual(actionNameRange.location, NSNotFound,
                      @"Did we change the action name?");
    NSRange viewDescriptionRange = [exception.reason rangeOfString:[view grey_description]];
    XCTAssertNotEqual(viewDescriptionRange.location, NSNotFound,
                      @"Did we change the element description?");
  }
}

- (void)testSwipeOnViewWithoutWindow {
  // First, disable other constraint checks so the action won't fail because of them
  [[GREYConfiguration sharedInstance] setValue:@NO
                                  forConfigKey:kGREYConfigKeyActionConstraintsEnabled];

  UIView *view = [[UIView alloc] init];
  [[[self.mockSharedApplication stub]
      andReturnValue:@(UIDeviceOrientationPortrait)] statusBarOrientation];
  id<GREYAction> swipeLeft = [GREYActions actionForSwipeFastInDirection:kGREYDirectionLeft];

  @try {
    [swipeLeft perform:view error:nil];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *reason = @"Cannot swipe on view [V], as it has no window and "
        @"it isn't a window itself.";
    XCTAssertEqualObjects([exception name], kGREYGenericFailureException,
                          @"Should throw GREYActionFailException");
    NSRange reasonRange = [exception.reason rangeOfString:reason];
    XCTAssertNotEqual(reasonRange.location, NSNotFound,
                      @"Did we change the exception reason?");
    NSRange viewDescriptionRange = [exception.reason rangeOfString:[view grey_description]];
    XCTAssertNotEqual(viewDescriptionRange.location, NSNotFound,
                      @"Did we change the element description?");
  }
}

- (void)testTapDisabledControl {
  UIControl *view = [[UIControl alloc] init];

  // Mock out [GREYMatchers matcherForSufficientlyVisible] for a matcher that matches anything.
  id mockMatcher = [OCMockObject mockForProtocol:@protocol(GREYMatcher)];
  OCMStub([mockMatcher matches:OCMOCK_ANY]).andReturn(@YES);
  id mockGREYMatchers = OCMClassMock([GREYMatchers class]);
  OCMStub([mockGREYMatchers matcherForSufficientlyVisible]).andReturn(mockMatcher);

  view.enabled = NO;
  id<GREYAction> tap = [GREYActions actionForTap];
  @try {
    [tap perform:view error:nil];
    XCTFail(@"Should have thrown an exception");
  } @catch (NSException *exception) {
    NSString *reason = @"Cannot perform action due to constraint(s) failure.";
    XCTAssertEqualObjects([exception name], kGREYActionFailedException,
                          @"Should throw GREYActionFailException");
    NSRange reasonRange = [exception.reason rangeOfString:reason];
    XCTAssertNotEqual(reasonRange.location, NSNotFound,
                      @"Did we change the exception reason?");
    NSRange viewDescriptionRange = [exception.reason rangeOfString:[view grey_description]];
    XCTAssertNotEqual(viewDescriptionRange.location, NSNotFound,
                      @"Did we change the element description?");

  }
}

- (void)testInvalidTapActionSucceedsAfterDisablingConstraints {
  [[GREYConfiguration sharedInstance] setValue:@NO
                                  forConfigKey:kGREYConfigKeyActionConstraintsEnabled];

  UIView *view = [[UIView alloc] init];
  id<GREYAction> tap = [GREYActions actionForTap];
  @try {
    [tap perform:view error:nil];
  }
  @catch (NSException *exception) {
    XCTFail(@"Action should succeed without constraint checks.");
  }
}

- (void)testReplaceTextSucceedsOnUITextField {
    NSString *textToReplace = @"A String";
    NSError *error;

    UITextField *textfield = [[UITextField alloc] init];

    id<GREYAction> replace = [GREYActions actionForReplaceText:textToReplace];
    [replace perform:textfield error:&error];

    XCTAssertNil(error);
    XCTAssertEqualObjects(textToReplace, textfield.text);
}

- (void)testReplaceTextFailsOnUIView {
  NSString *textToReplace = @"A String";
  GREYError *error;

  UIView *view = [[UIView alloc] init];

  id<GREYAction> replace = [GREYActions actionForReplaceText:textToReplace];
  [replace perform:view error:&error];

  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain,
                        @"Wrong error domain.");
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode,
                 @"Wrong error code");
  NSString *actionName = [NSString stringWithFormat:@"Replace with text: \"%@\"", textToReplace];
  XCTAssertEqualObjects(error.errorInfo[kErrorDetailActionNameKey], actionName,
                        @"Wrong error action.");
  XCTAssertEqualObjects(error.errorInfo[@"Element Description"], [view grey_description],
                        @"Wrong error element description.");
}

@end

