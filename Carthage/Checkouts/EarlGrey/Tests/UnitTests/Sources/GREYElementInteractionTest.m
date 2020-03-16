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

#import <EarlGrey/GREYAction.h>
#import <EarlGrey/GREYActionBlock.h>
#import <EarlGrey/GREYActions.h>
#import <EarlGrey/GREYAssertion.h>
#import <EarlGrey/GREYAssertionBlock.h>
#import <EarlGrey/GREYAssertions.h>
#import <EarlGrey/GREYElementInteraction.h>
#import <EarlGrey/GREYFrameworkException.h>
#import <EarlGrey/GREYMatchers.h>
#import <EarlGrey/GREYNot.h>
#import "GREYBaseTest.h"
#import "GREYExposedForTesting.h"

NSMutableArray *appWindows;

@interface GREYElementInteractionTest : GREYBaseTest

@end

@implementation GREYElementInteractionTest {
  GREYElementInteraction *_elementInteraction;
}

- (void)setUp {
  [super setUp];

  appWindows = [[NSMutableArray alloc] init];
  [[[self.mockSharedApplication stub] andReturn:appWindows] windows];

  id viewMatcher = grey_ancestor(grey_kindOfClass([UIWindow class]));
  _elementInteraction = [[GREYElementInteraction alloc] initWithElementMatcher:viewMatcher];
}

- (void)testPerformInSpecificRoot {
  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];
  view1.accessibilityIdentifier = @"view1";
  view2.accessibilityIdentifier = @"view2";

  UIWindow *window1 = [[UIWindow alloc] init];
  UIWindow *window2 = [[UIWindow alloc] init];

  window1.accessibilityIdentifier = @"window1";
  window2.accessibilityIdentifier = @"window2";

  [window1 addSubview:view1];
  [window2 addSubview:view2];

  [appWindows addObjectsFromArray:@[ window1, window2 ]];

  _elementInteraction =
      [[GREYElementInteraction alloc] initWithElementMatcher:grey_accessibilityID(@"view1")];
  [_elementInteraction inRoot:grey_accessibilityID(@"window1")];

  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    return YES;
  }];
  XCTAssertNoThrow([_elementInteraction performAction:action]);

  [_elementInteraction inRoot:grey_accessibilityID(@"window2")];
  XCTAssertThrows([_elementInteraction performAction:action]);

  _elementInteraction =
     [[GREYElementInteraction alloc] initWithElementMatcher:grey_accessibilityID(@"view2")];
  [_elementInteraction inRoot:grey_accessibilityID(@"window2")];
  XCTAssertNoThrow([_elementInteraction performAction:action]);
}

- (void)testPerformWithNoRootSpecified {
  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];
  view1.accessibilityIdentifier = @"view1";
  view2.accessibilityIdentifier = @"view2";

  UIWindow *window1 = [[UIWindow alloc] init];
  UIWindow *window2 = [[UIWindow alloc] init];

  window1.accessibilityIdentifier = @"window1";
  window2.accessibilityIdentifier = @"window2";

  [window1 addSubview:view1];
  [window2 addSubview:view2];

  [appWindows addObjectsFromArray:@[ window1, window2 ]];

  _elementInteraction =
      [[GREYElementInteraction alloc] initWithElementMatcher:grey_accessibilityID(@"view1")];
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    return YES;
  }];
  XCTAssertNoThrow([_elementInteraction performAction:action]);

  _elementInteraction =
      [[GREYElementInteraction alloc] initWithElementMatcher:grey_accessibilityID(@"view2")];
  XCTAssertNoThrow([_elementInteraction performAction:action]);
}

- (void)testPerformWithNilView {
  XCTAssertThrowsSpecificNamed([_elementInteraction performAction:grey_tap()],
                               GREYFrameworkException,
                               kGREYNoMatchingElementException,
                               @"Should throw exception if no UI elements returned");
}

- (void)testPerformWithMultipleViewsThrowsExceptionIfMultipleElementsAreMatched {
  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];
  UIWindow *window = [[UIWindow alloc] init];
  [window addSubview:view1];
  [window addSubview:view2];
  [appWindows addObject:window];

  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    return YES;
  }];

  XCTAssertThrowsSpecificNamed([_elementInteraction performAction:action],
                               GREYFrameworkException,
                               kGREYMultipleElementsFoundException);
}

- (void)testPerformWithMultipleViewsReturnsAppropriateError {
  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];
  UIWindow *window = [[UIWindow alloc] init];
  [window addSubview:view1];
  [window addSubview:view2];
  [appWindows addObject:window];

  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    return YES;
  }];

  NSError *error;
  [_elementInteraction performAction:action error:&error];
  XCTAssertEqual(error.code, kGREYInteractionMultipleElementsMatchedErrorCode);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
}

- (void)testPerformCallsAction {
  UIView *view1 = [[UIView alloc] init];
  UIWindow *window = [[UIWindow alloc] init];
  [window addSubview:view1];
  [appWindows addObject:window];

  __block BOOL called = NO;
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    called = YES;
    return YES;
  }];
  [_elementInteraction performAction:action];
  XCTAssertTrue(called, @"Action should be performed");
}

- (void)testPerformWithErrorDoesNotThrowException {
  [self grey_setupWindows];

  NSError *expectedError = [NSError errorWithDomain:@"test" code:1234 userInfo:nil];
  __block BOOL called = NO;
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    called = YES;
    if (errorOrNil) {
      *errorOrNil = expectedError;
    }
    return NO;
  }];

  NSError *actualError;
  XCTAssertNoThrow([_elementInteraction performAction:action error:&actualError]);

  XCTAssertEqualObjects(actualError, expectedError);
  XCTAssertTrue(called, @"Action block should be called.");
}

- (void)testPerformWithErrorElementNotFound {
  __block BOOL called = NO;
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    called = YES;
    return NO;
  }];

  NSError *actualError;
  [_elementInteraction performAction:action error:&actualError];

  XCTAssertFalse(called, @"Action block should not be called because element wasn't found.");
  XCTAssertEqual(actualError.code, kGREYInteractionElementNotFoundErrorCode);
  XCTAssertEqualObjects(actualError.domain, kGREYInteractionErrorDomain);
}

- (void)testPerformWithErrorFailsWithoutReason {
  [self grey_setupWindows];

  __block BOOL called = NO;
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    called = YES;
    return NO;
  }];

  NSDictionary *userInfo =
      @{ NSLocalizedDescriptionKey : @"Reason for action failure was not provided." };
  NSError *expectedError = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                               code:kGREYInteractionActionFailedErrorCode
                                           userInfo:userInfo];
  NSError *actualError;
  [_elementInteraction performAction:action error:&actualError];
  XCTAssertEqualObjects(actualError, expectedError);
  XCTAssertTrue(called, @"Action block should be called.");
}

- (void)testPerformWithNilError {
  [self grey_setupWindows];

  NSError *expectedError = [NSError errorWithDomain:@"test" code:1234 userInfo:nil];
  __block BOOL called = NO;
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    called = YES;
    if (errorOrNil) {
      *errorOrNil = expectedError;
    }
    return NO;
  }];

  XCTAssertThrowsSpecificNamed([_elementInteraction performAction:action error:nil],
                               GREYFrameworkException,
                               kGREYActionFailedException);
  XCTAssertTrue(called, @"Action block should be called.");
}

- (void)testPerformWithErrorActionSucceeds {
  [self grey_setupWindows];

  NSError *expectedError;
  __block BOOL called = NO;
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
                                               called = YES;
                                               return YES;
                                             }];

  [_elementInteraction performAction:action error:&expectedError];
  XCTAssertNil(expectedError);
  XCTAssertTrue(called, @"Action block should be called.");
}

- (void)testCheckWithNilError {
  [self grey_setupWindows];

  __block BOOL called = NO;
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL (id element, NSError *__strong *errorOrNil) {
                      called = YES;
                      return YES;
                    }];

  XCTAssertNoThrow([_elementInteraction assert:assertion error:nil]);
  XCTAssertTrue(called);
}

- (void)testCheckWithErrorDoesNotThrowException {
  [self grey_setupWindows];

  __block BOOL called = NO;
  NSError *expectedError = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                               code:kGREYInteractionAssertionFailedErrorCode
                                           userInfo:nil];
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL (id element, NSError *__strong *errorOrNil) {
                      called = YES;
                      if (errorOrNil) {
                        *errorOrNil = expectedError;
                      }
                      return NO;
                    }];

  NSError *actualError;
  XCTAssertNoThrow([_elementInteraction assert:assertion error:&actualError]);
  XCTAssertEqualObjects(actualError, expectedError);
  XCTAssertTrue(called);
}

- (void)testCheckWithErrorElementNotFound {
  __block BOOL called = NO;
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL (id element, NSError *__strong *errorOrNil) {
        called = YES;
        if (errorOrNil) {
          *errorOrNil = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                            code:kGREYInteractionElementNotFoundErrorCode
                                        userInfo:nil];
        }
        return NO;
      }];

  NSError *actualError;
  XCTAssertNoThrow([_elementInteraction assert:assertion error:&actualError]);
  XCTAssertEqualObjects(actualError.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(actualError.code, kGREYInteractionElementNotFoundErrorCode);
  XCTAssertTrue(called, @"Assertion should be called even though element is nil.");
}

- (void)testCheckWithErrorFailsWithoutReason {
  __block BOOL called = NO;
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL (id element, NSError *__strong *errorOrNil) {
                      called = YES;
                      return NO;
                    }];

  NSDictionary *userInfo =
      @{ NSLocalizedDescriptionKey : @"Reason for assertion failure was not provided." };
  NSError *expectedError = [NSError errorWithDomain:kGREYInteractionErrorDomain
                                               code:kGREYInteractionAssertionFailedErrorCode
                                           userInfo:userInfo];
  NSError *actualError;
  XCTAssertNoThrow([_elementInteraction assert:assertion error:&actualError]);
  XCTAssertEqualObjects(actualError, expectedError);
  XCTAssertTrue(called, @"Assertion block should be called.");
}

- (void)testCheckWithMultipleViewsThrowsExceptionIfMultipleElementsAreMatched {
  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];
  UIWindow *window = [[UIWindow alloc] init];
  [window addSubview:view1];
  [window addSubview:view2];
  [appWindows addObject:window];

  XCTAssertThrowsSpecificNamed([_elementInteraction assertWithMatcher:grey_anything()],
                               GREYFrameworkException,
                               kGREYMultipleElementsFoundException);
}

- (void)testCheckWithMultipleViewsReturnsAppropriateError {
  UIView *view1 = [[UIView alloc] init];
  UIView *view2 = [[UIView alloc] init];
  UIWindow *window = [[UIWindow alloc] init];
  [window addSubview:view1];
  [window addSubview:view2];
  [appWindows addObject:window];

  NSError *error;
  [_elementInteraction assertWithMatcher:grey_anything() error:&error];
  XCTAssertEqual(error.code, kGREYInteractionMultipleElementsMatchedErrorCode);
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
}

- (void)testCheckCallsAssertion {
  [self grey_setupWindows];

  __block BOOL called = NO;
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                      called = YES;
                      return YES;
                    }];
  [_elementInteraction assert:assertion];
  XCTAssertTrue(called, @"Assert should call assertion");
}

- (void)testDefaultFailureHandler {
  // To test output of the failure handler
  id<GREYMatcher> matcher = grey_anyOf(grey_accessibilityTrait(UIAccessibilityTraitAdjustable),
                                       grey_not(grey_text(@"X")),
                                       nil);
  _elementInteraction = [[GREYElementInteraction alloc] initWithElementMatcher:matcher];
  id<GREYAction> action = [GREYActions actionForTap];
  XCTAssertThrowsSpecificNamed([_elementInteraction performAction: action],
                               GREYFrameworkException,
                               kGREYNoMatchingElementException,
                               @"\"%@\" assertion not performed because "
                               "no UI elements matching the provided matcher "
                               "%@ was found.",
                               action,
                               matcher);
}

- (void)testWillCheckAssertionNotification {
  __block BOOL notificationPosted = NO;
  __block id<GREYAssertion> assertionMade = nil;
  __block UIView *assertedView = [[UIView alloc] init];
  [self grey_setupWindows];
  UIView *windowView = [[[appWindows firstObject] subviews] firstObject];
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                      XCTAssertTrue(notificationPosted);
                      return YES;
                    }];

  void (^notificationBlock)(NSNotification *notification) = ^(NSNotification *notification) {
    notificationPosted = YES;
    assertionMade = [notification.userInfo objectForKey:kGREYAssertionUserInfoKey];
    assertedView = [notification.userInfo objectForKey:kGREYAssertionElementUserInfoKey];
  };

  id notificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYWillPerformAssertionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:notificationBlock];
  [_elementInteraction assert:assertion];
  XCTAssertTrue(notificationPosted);
  XCTAssertEqual(assertionMade, assertion);
  XCTAssertEqual(assertedView, windowView);
  XCTAssertNotNil(assertionMade);
  XCTAssertNotNil(assertedView);
  [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}


- (void)testDidCheckAssertionNotification {
  __block BOOL notificationPosted = NO;
  __block id<GREYAssertion> assertionMade = nil;
  __block UIView *assertedView = [[UIView alloc] init];
  [self grey_setupWindows];
  UIView *windowView = [[[appWindows firstObject] subviews] firstObject];
  __block BOOL called = NO;
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"name"
                    assertionBlockWithError:^BOOL(id element, NSError *__strong *errorOrNil) {
                      called = YES;
                      XCTAssertFalse(notificationPosted);
                      return YES;
                    }];
  void (^notificationBlock)(NSNotification *notification) = ^(NSNotification *notification) {
    notificationPosted = YES;
    assertionMade = [notification.userInfo objectForKey:kGREYAssertionUserInfoKey];
    assertedView = [notification.userInfo objectForKey:kGREYAssertionElementUserInfoKey];
  };
  id notificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYDidPerformAssertionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:notificationBlock];
  [_elementInteraction assert:assertion];
  XCTAssertTrue(notificationPosted);
  XCTAssertEqual(assertionMade, assertion);
  XCTAssertEqual(assertedView, windowView);
  XCTAssertNotNil(assertionMade);
  XCTAssertNotNil(assertedView);
  [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

- (void)testBothAssertionNotificationsPosted {
  __block BOOL willPerformNotificationPosted = NO;
  __block BOOL didPerformNotificationPosted = NO;
  __block id element = nil;
  __block NSError *assertionError = nil;
  GREYCheckBlockWithError checkBlock = ^BOOL(id element, NSError *__strong *errorOrNil) {
    if (errorOrNil != NULL) *errorOrNil = [NSError errorWithDomain:@"test" code:200 userInfo:nil];
    return NO;
  };
  id<GREYAssertion> assertion = [GREYAssertionBlock assertionWithName:@"test"
                                              assertionBlockWithError:checkBlock];
  void (^willPerformNotificationBlock)(NSNotification *willPerformNotification) =
      ^(NSNotification *notification) {
        willPerformNotificationPosted = YES;
        element = [notification.userInfo objectForKey:kGREYAssertionElementUserInfoKey];
      };
  void (^didPerformNotificationBlock)(NSNotification *didPerformNotification) =
      ^(NSNotification *notification) {
        didPerformNotificationPosted = YES;
        assertionError = [notification.userInfo objectForKey:kGREYAssertionErrorUserInfoKey];
      };
  id willPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYWillPerformAssertionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willPerformNotificationBlock];
  id didPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYDidPerformAssertionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didPerformNotificationBlock];
  NSError *error;
  [_elementInteraction assert:assertion error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.domain, @"test");
  XCTAssertEqual(error.code, 200);
  XCTAssertNotNil(assertionError);
  XCTAssertNil(element);
  XCTAssertTrue(willPerformNotificationPosted);
  XCTAssertTrue(didPerformNotificationPosted);
  [[NSNotificationCenter defaultCenter] removeObserver:willPerformNotificationObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:didPerformNotificationObserver];
}

- (void)testWillPerformActionNotification {
  __block BOOL notificationPosted = NO;
  __block id<GREYAction> actionMade = nil;
  __block UIView *actedUponView = [[UIView alloc] init];
  [self grey_setupWindows];
  UIView *windowView = [[[appWindows firstObject] subviews] firstObject];
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test"
                                             performBlock:^(id element,
                                                            __strong NSError **errorOrNil) {
    XCTAssertTrue(notificationPosted);
    return YES;
  }];
  void (^notificationBlock)(NSNotification *notification) = ^(NSNotification *notification) {
    notificationPosted = YES;
    actionMade = [notification.userInfo objectForKey:kGREYActionUserInfoKey];
    actedUponView = [notification.userInfo objectForKey:kGREYActionElementUserInfoKey];
  };

  id notificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYWillPerformActionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:notificationBlock];
  [_elementInteraction performAction:action error:nil];
  XCTAssertTrue(notificationPosted);
  XCTAssertEqual(actionMade, action);
  XCTAssertEqual(actedUponView, windowView);
  XCTAssertNotNil(actionMade);
  XCTAssertNotNil(actedUponView);
  [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

- (void)testDidPerformActionNotification {
  __block BOOL notificationPosted = NO;
  __block id<GREYAction> actionMade = nil;
  __block UIView *actedUponView = [[UIView alloc] init];
  [self grey_setupWindows];
  UIView *windowView = [[[appWindows firstObject] subviews] firstObject];
  GREYPerformBlock performBlock = ^(id element, __strong NSError **errorOrNil) {
    XCTAssertFalse(notificationPosted);
    return YES;
  };
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test" performBlock:performBlock];
  void (^notificationBlock)(NSNotification *notification) = ^(NSNotification *notification) {
    notificationPosted = YES;
    actionMade = [notification.userInfo objectForKey:kGREYActionUserInfoKey];
    actedUponView = [notification.userInfo objectForKey:kGREYActionElementUserInfoKey];
  };
  id notificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYDidPerformActionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:notificationBlock];
  [_elementInteraction performAction:action error:nil];
  XCTAssertTrue(notificationPosted);
  XCTAssertEqual(actionMade, action);
  XCTAssertEqual(actedUponView, windowView);
  XCTAssertNotNil(actionMade);
  XCTAssertNotNil(actedUponView);
  [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

- (void)testBothActionNotificationsPosted {
  __block BOOL willPerformNotificationPosted = NO;
  __block BOOL didPerformNotificationPosted = NO;
  __block id element = nil;
  __block NSError *actionError = nil;
  GREYPerformBlock performBlock = ^(id element, __strong NSError **errorOrNil) {
    if (errorOrNil != NULL) *errorOrNil = [NSError errorWithDomain:@"test" code:200 userInfo:nil];
    return NO;
  };
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test" performBlock:performBlock];
  void (^willPerformNotificationBlock)(NSNotification *willPerformNotification) =
      ^(NSNotification *notification) {
         willPerformNotificationPosted = YES;
         element = [notification.userInfo objectForKey:kGREYActionElementUserInfoKey];
      };
  void (^didPerformNotificationBlock)(NSNotification *didPerformNotification) =
      ^(NSNotification *notification) {
         didPerformNotificationPosted = YES;
         actionError = [notification.userInfo objectForKey:kGREYActionErrorUserInfoKey];
      };
  id willPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYWillPerformActionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willPerformNotificationBlock];
  id didPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYDidPerformActionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didPerformNotificationBlock];
  NSError *error;
  [_elementInteraction performAction:action error:&error];
  XCTAssertNotNil(error);
  // No element found means that the error will be a no element found error and not custom error.
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionElementNotFoundErrorCode);
  // Error should still be set even if no element was found.
  XCTAssertEqualObjects(actionError.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(actionError.code, kGREYInteractionElementNotFoundErrorCode);
  XCTAssertNil(element);
  XCTAssertTrue(willPerformNotificationPosted);
  XCTAssertTrue(didPerformNotificationPosted);
  [[NSNotificationCenter defaultCenter] removeObserver:willPerformNotificationObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:didPerformNotificationObserver];
}

- (void)testActionNotificationWithErrorPosted {
  __block BOOL willPerformNotificationPosted = NO;
  __block BOOL didPerformNotificationPosted = NO;
  __block NSError *actionError = nil;
  __block id element = nil;
  [self grey_setupWindows];
  UIWindow *window = (UIWindow *)[appWindows firstObject];
  window.isAccessibilityElement = NO;
  UIView *mainView = [[[appWindows firstObject] subviews] firstObject];
  mainView.isAccessibilityElement = NO;
  GREYPerformBlock performBlock = ^(id element, __strong NSError **errorOrNil) {
    if (errorOrNil != NULL) *errorOrNil = [NSError errorWithDomain:@"test" code:200 userInfo:nil];
    return NO;
  };
  id<GREYAction> action = [GREYActionBlock actionWithName:@"test" performBlock:performBlock];
  void (^willPerformNotificationBlock)(NSNotification *willPerformNotification) =
      ^(NSNotification *notification) {
        willPerformNotificationPosted = YES;
      };
  void (^didPerformNotificationBlock)(NSNotification *didPerformNotification) =
      ^(NSNotification *notification) {
        didPerformNotificationPosted = YES;
        element = [notification.userInfo objectForKey:kGREYActionElementUserInfoKey];
        actionError = [notification.userInfo objectForKey:kGREYActionErrorUserInfoKey];
      };
  id willPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYWillPerformActionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willPerformNotificationBlock];
  id didPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYDidPerformActionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didPerformNotificationBlock];

  NSError *error;
  [_elementInteraction performAction:action error:&error];
  XCTAssertNotNil(error);
  XCTAssertNotNil(element);
  XCTAssertEqual(error, actionError);
  XCTAssertTrue(willPerformNotificationPosted);
  XCTAssertTrue(didPerformNotificationPosted);
  [[NSNotificationCenter defaultCenter] removeObserver:willPerformNotificationObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:didPerformNotificationObserver];
}

- (void)testAssertionNotificationWithErrorPosted {
  __block BOOL willPerformNotificationPosted = NO;
  __block BOOL didPerformNotificationPosted = NO;
  __block NSError *assertionError = nil;
  GREYCheckBlockWithError checkBlock = ^BOOL(id element, NSError *__strong *errorOrNil) {
    if (errorOrNil != NULL) *errorOrNil = [NSError errorWithDomain:@"test" code:200 userInfo:nil];
    return NO;
  };
  id<GREYAssertion> assertion =
      [GREYAssertionBlock assertionWithName:@"assert" assertionBlockWithError:checkBlock];
  void (^willPerformNotificationBlock)(NSNotification *willPerformNotification) =
      ^(NSNotification *notification) {
        willPerformNotificationPosted = YES;
      };
  void (^didPerformNotificationBlock)(NSNotification *didPerformNotification) =
      ^(NSNotification *notification) {
        didPerformNotificationPosted = YES;
        assertionError = [notification.userInfo objectForKey:kGREYAssertionErrorUserInfoKey];
      };
  id willPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYWillPerformAssertionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:willPerformNotificationBlock];
  id didPerformNotificationObserver =
      [[NSNotificationCenter defaultCenter] addObserverForName:kGREYDidPerformAssertionNotification
                                                        object:nil
                                                         queue:nil
                                                    usingBlock:didPerformNotificationBlock];

  NSError *error;
  [_elementInteraction assert:assertion error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.domain, @"test");
  XCTAssertEqual(error.code, 200);
  XCTAssertNotNil(assertionError);
  XCTAssertTrue(willPerformNotificationPosted);
  XCTAssertTrue(didPerformNotificationPosted);
  [[NSNotificationCenter defaultCenter] removeObserver:willPerformNotificationObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:didPerformNotificationObserver];
}

- (void)testUIThreadExecutorTimesOutWhilePerformingSearchActionAndSearchActionIsPerformedOnlyOnce {
  UIView *view1 = [[UIView alloc] init];
  view1.accessibilityIdentifier = @"view1";

  UIWindow *window = [[UIWindow alloc] init];
  window.accessibilityIdentifier = @"window1";

  [appWindows addObjectsFromArray:@[ window ]];

  __block NSUInteger count = 0;
  // Make the app not idle.
  NSObject *object = [[NSObject alloc] init];
  id<GREYAction> action =
      [GREYActionBlock actionWithName:@"SearchAction"
                        performBlock:^BOOL(id element, NSError *__strong *errorOrNil) {
                          [window addSubview:view1];
                          [[GREYAppStateTracker sharedInstance] trackState:kGREYPendingViewsToAppear
                                                                 forObject:object];
                          ++count;
                          return YES;
  }];

  // Setting the timeout time to 0 seconds to check if the search action is at least executed once.
  [[GREYConfiguration sharedInstance] setValue:@0
                                  forConfigKey:kGREYConfigKeyInteractionTimeoutDuration];

  // Mock the GREYUIThreadExecutor to return @c YES. This is so because the main dipatch queue
  // may not be idle due to system service and this may cause the search action to fail.
  // The following mocking makes the search action to execute, and after that the original
  // implementation will be invoked.
  id mockUIThreadExecutor =
      [OCMockObject partialMockForObject:[GREYUIThreadExecutor sharedInstance]];
  [[[mockUIThreadExecutor expect] andReturnValue:@YES] grey_areAllResourcesIdle];
  [[[mockUIThreadExecutor expect] andReturnValue:@YES] grey_areAllResourcesIdle];

  NSError *error;
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"view1")]
      usingSearchAction:action
      onElementWithMatcher:grey_kindOfClass([UIWindow class])] performAction:grey_tap()
                                                                       error:&error];
  // The interaction should time out after the search action is executed.
  NSUInteger location =
      [error.description rangeOfString:@"Interaction timed out"].location != NSNotFound;
  XCTAssertTrue(location, @"Interaction should time out.");

  // Make sure that the search action was performed only once.
  XCTAssertEqual(count, 1u);

  [mockUIThreadExecutor verify];
  [mockUIThreadExecutor stopMocking];
}

#pragma mark - Private

/**
 *  Set the app's windows with a UIWindow with a single UIView.
 */
- (void)grey_setupWindows {
  UIWindow *window = [[UIWindow alloc] init];
  UIView *view1 = [[UIView alloc] init];
  [window addSubview:view1];
  [appWindows addObject:window];
}

@end
