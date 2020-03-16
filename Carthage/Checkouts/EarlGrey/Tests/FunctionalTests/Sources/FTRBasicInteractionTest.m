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

@interface FTRBasicInteractionTest : FTRBaseIntegrationTest
@end

@implementation FTRBasicInteractionTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Basic Views"];
}

- (void)testEarlGreyInvocationInsideGREYConditionUsingWaitWithLargeTimeout {
  GREYCondition *condition = [GREYCondition conditionWithName:@"conditionWithAction" block:^BOOL {
    static double stepperValue = 51;
    [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
        performAction:[GREYActions actionForSetStepperValue:++stepperValue]];
    return stepperValue == 55;
  }];
  [condition waitWithTimeout:10.0];

  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      assertWithMatcher:grey_stepperValue(55)];
}

- (void)testEarlGreyInvocationInsideGREYConditionUsingWaitWithTimeout {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  // Setup an action that grabs a label and returns its text
  __block NSString *text;
  id actionBlock = ^(UILabel *element, __strong NSError **errorOrNil) {
    text = element.text;
    return YES;
  };
  id<GREYAction> action = [GREYActionBlock actionWithName:@"GetSampleLabelText"
                                             performBlock:actionBlock];

  // Setup a condition to wait until a specific label says specific text.
  GREYCondition *waitCondition = [GREYCondition conditionWithName:@"WaitForLabelText"
                                                            block:^BOOL() {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"sampleLabel")] performAction:action];
    return [text isEqualToString:@"OFF"];
  }];

  // Switch text and wait.
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Switch"]]
      performAction:[GREYActions actionForTurnSwitchOn:NO]];
  [waitCondition waitWithTimeout:10.0];
}

- (void)testTapOnWindow {
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:[GREYActions actionForTap]];

  UITapGestureRecognizer *tapGestureRecognizer =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ftr_dismissWindow:)];
  tapGestureRecognizer.numberOfTapsRequired = 1;

  // Create a custom window that dismisses itself when tapped.
  UIWindow *topMostWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [topMostWindow addGestureRecognizer:tapGestureRecognizer];

  topMostWindow.accessibilityIdentifier = @"TopMostWindow";
  topMostWindow.isAccessibilityElement = YES;
  [topMostWindow makeKeyAndVisible];

  // Tap on topmost window.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TopMostWindow")]
      performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TopMostWindow")]
      assertWithMatcher:grey_notVisible()];
}

- (void)testRootViewControllerSetMultipleTimesOnMainWindow {
  UIWindow *currentWindow = [[UIApplication sharedApplication].delegate window];
  UIViewController *originalVC = currentWindow.rootViewController;

  UIViewController *vc1 = [[UIViewController alloc] init];
  [currentWindow setRootViewController:vc1];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      assertWithMatcher:grey_nil()];
  [currentWindow setRootViewController:nil];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      assertWithMatcher:grey_nil()];

  [currentWindow setRootViewController:originalVC];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      assertWithMatcher:grey_notNil()];
}

- (void)testRootViewControllerSetOnMultipleWindows {
  UIWindow *currentWindow = [[UIApplication sharedApplication].delegate window];
  UIViewController *originalVC = currentWindow.rootViewController;

  UIWindow *otherWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [otherWindow setRootViewController:originalVC];
  [currentWindow setRootViewController:nil];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      assertWithMatcher:grey_nil()];

  [otherWindow setRootViewController:nil];
  [currentWindow setRootViewController:originalVC];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      assertWithMatcher:grey_notNil()];
}

- (void)testBasicInteractionWithViews {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  GREYElementInteraction *typeHere =
      [EarlGrey selectElementWithMatcher:grey_allOf(grey_accessibilityLabel(@"Type Something Here"),
                                                    grey_kindOfClass([UITextField class]),
                                                    nil)];

  [[typeHere performAction:[GREYActions actionForReplaceText:@"Hello 2"]]
      assertWithMatcher:grey_text(@"Hello 2")];

  [typeHere performAction:[GREYActions actionForClearText]];

  [[typeHere performAction:grey_tapAtPoint(CGPointMake(0, 0))]
      performAction:[GREYActions actionForTypeText:@"Hello!"]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Send"]]
      performAction:grey_tapAtPoint(CGPointMake(5, 5))];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Simple Label"]]
      assertWithMatcher:grey_text(@"Hello!")];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Switch"]]
      performAction:[GREYActions actionForTurnSwitchOn:NO]];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Simple Label"]]
      assertWithMatcher:grey_text(@"OFF")];

  [[[EarlGrey selectElementWithMatcher:grey_text(@"Long Press")]
      performAction:[GREYActions actionForLongPressWithDuration:1.1f]]
      assertWithMatcher:[GREYMatchers matcherForNotVisible]];

  [[[EarlGrey selectElementWithMatcher:grey_text(@"Double Tap")]
      performAction:grey_doubleTap()]
      assertWithMatcher:[GREYMatchers matcherForNotVisible]];
}

- (void)testEarlGreyInvocationInsideCustomAction {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActionBlock actionWithName:@"PerformIfVisibleElseFail"
                                       performBlock:^(id element,
                                                      __strong NSError **errorOrNil) {
        if (![element isHidden]) {
          [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
              performAction:[GREYActions actionForTap]];
          [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
              performAction:[GREYActions actionForLongPressWithDuration:1.1f]]
              assertWithMatcher:grey_nil()];
        } else {
          GREYFail(@"Element should exist. We should not be here.");
          return NO;
        }
        return YES;
      }]];
}

- (void)testEarlGreyInvocationInsideCustomAssertion {
  [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")]
      assert:[GREYAssertionBlock assertionWithName:@"ConditionalTapIfElementExists"
                           assertionBlockWithError:^BOOL(id element,
                                                         NSError *__strong *errorOrNil) {
        if (element) {
          [[EarlGrey selectElementWithMatcher:grey_text(@"Tab 2")] performAction:grey_tap()];
          [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
              performAction:[GREYActions actionForLongPressWithDuration:1.1f]]
              assertWithMatcher:grey_nil()];
        } else {
          GREYFail(@"Element should exist. We should not be here.");
        }
        return YES;
      }]];
}

- (void)testLongPressOnAccessibilityElement {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      performAction:[GREYActions actionForLongPressWithDuration:1.1f]]
      assertWithMatcher:grey_nil()];
}

- (void)testLongPressAtPointOnAccessibilityElement {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Long Press")]
      performAction:[GREYActions actionForLongPressAtPoint:CGPointMake(10, 10) duration:1.1f]]
      assertWithMatcher:grey_nil()];
}

- (void)DISABLED_testLongPressOnTextField {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
     performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
     performAction:[GREYActions actionForLongPressWithDuration:1.0f]];

  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
     assertWithMatcher:grey_notNil()];
}

- (void)testLongPressFollowedBySelectingMenuOption {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:[GREYActions actionForTypeText:@"Hello"]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:[GREYActions actionForLongPressAtPoint:CGPointMake(1, 1) duration:1.0]];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Select")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Cut")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:[GREYActions actionForTypeText:@"FromEarlGrey"]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"foo")]
      performAction:[GREYActions actionForLongPressAtPoint:CGPointMake(1, 1) duration:1.0]];

  [[EarlGrey selectElementWithMatcher:grey_text(@"Paste")]
      performAction:[GREYActions actionForTap]];

  // Smart Inserts in Xcode 9 cause a space to appear by default after a paste. This attribute
  // is not available on Xcode 7 and therefore cannot be used to fix the test. Therefore, we
  // are changing the value based on the Xcode version.
  if (iOS11_OR_ABOVE()) {
    [[EarlGrey selectElementWithMatcher:grey_text(@"Hello FromEarlGrey")]
        assertWithMatcher:grey_sufficientlyVisible()];
  } else {
    [[EarlGrey selectElementWithMatcher:grey_text(@"HelloFromEarlGrey")]
        assertWithMatcher:grey_sufficientlyVisible()];
  }
}

- (void)testBasicInteractionWithStepper {
  [[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      performAction:[GREYActions actionForSetStepperValue:87]];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Value Label")]
      assertWithMatcher:grey_text(@"Value: 87%")];
  [[[EarlGrey selectElementWithMatcher:grey_kindOfClass([UIStepper class])]
      performAction:[GREYActions actionForSetStepperValue:16]]
      assertWithMatcher:grey_stepperValue(16)];
}

- (void)testInteractionWithUISwitch {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  [[[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Switch"]]
      performAction:[GREYActions actionForTurnSwitchOn:NO]]
      assertWithMatcher:grey_switchWithOnState(NO)];

  [[[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Switch"]]
      performAction:[GREYActions actionForTurnSwitchOn:YES]]
      assertWithMatcher:grey_switchWithOnState(YES)];

  [[[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Switch"]]
      performAction:[GREYActions actionForTurnSwitchOn:YES]]
      assertWithMatcher:grey_switchWithOnState(YES)];

  [[[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Switch"]]
      performAction:[GREYActions actionForTurnSwitchOn:NO]]
      assertWithMatcher:grey_switchWithOnState(NO)];
}

- (void)testInteractionWithHiddenLabel {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Hidden Label"]]
      assertWithMatcher:grey_text(@"Hidden Label")];
}

- (void)testInteractionWithLabelWithParentWithAlphaZero {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
}

- (void)testInteractionWithLabelWithParentHiddenAndUnhidden {
  GREYActionBlock *hideTab2Block =
      [GREYActionBlock actionWithName:@"hideTab2"
                         performBlock:^BOOL(id element, NSError *__strong *error) {
                           UIView *superView = element;
                           superView.hidden = YES;
                           return YES;
      }];
  GREYActionBlock *unhideTab2Block =
      [GREYActionBlock actionWithName:@"unhideTab2"
                         performBlock:^BOOL(id element, NSError *__strong *error) {
                           UIView *superView = element;
                           superView.hidden = NO;
                           return YES;
      }];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"tab2Container"]]
      performAction:hideTab2Block];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"tab2Container"]]
      performAction:unhideTab2Block];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testInteractionWithLabelWithParentTranslucentAndOpaque {
  GREYActionBlock *makeTab2OpaqueBlock =
      [GREYActionBlock actionWithName:@"makeTab2Opaque"
                         performBlock:^BOOL(id element, NSError *__strong *error) {
                           UIView *superView = element;
                           superView.alpha = 1;
                           return YES;
      }];
  GREYActionBlock *makeTab2TranslucentBlock =
      [GREYActionBlock actionWithName:@"makeTab2Translucent"
                         performBlock:^BOOL(id element, NSError *__strong *error) {
                           UIView *superView = element;
                           superView.alpha = 0;
                           return YES;
      }];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"tab2Container"]]
      performAction:makeTab2TranslucentBlock];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"tab2Container"]]
      performAction:makeTab2OpaqueBlock];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/**
 *  No test is provided for the key window since changing its hidden value will
 *  cause other tests to fail since the keyWindow is modified.
 */
- (void)testInteractionWithLabelWithWindowTranslucentAndOpaque {
  GREYActionBlock *makeWindowOpaqueBlock =
      [GREYActionBlock actionWithName:@"unhideTab2"
                         performBlock:^BOOL(id element, NSError *__strong *error) {
                           UIView *view = element;
                           UIWindow *window = view.window;
                           window.alpha = 1;
                           return YES;
      }];
  GREYActionBlock *makeWindowTranslucentBlock =
      [GREYActionBlock actionWithName:@"hideTab2"
                         performBlock:^BOOL(id element, NSError *__strong *error) {
                           UIView *view = element;
                           UIWindow *window = view.window;
                           window.alpha = 0;
                           return YES;
      }];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"tab2Container"]]
      performAction:makeWindowTranslucentBlock];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_not(grey_sufficientlyVisible())];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"tab2Container"]]
      performAction:makeWindowOpaqueBlock];
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForAccessibilityLabel:@"Long Press"]]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testButtonSelectedState {
  [[EarlGrey selectElementWithMatcher:[GREYMatchers matcherForText:@"Tab 2"]]
      performAction:[GREYActions actionForTap]];

  id<GREYMatcher> buttonMatcher = grey_allOf(grey_kindOfClass([UIButton class]),
                                             grey_descendant(grey_accessibilityLabel(@"Send")),
                                             nil);

  [[EarlGrey selectElementWithMatcher:buttonMatcher] assertWithMatcher:grey_not(grey_selected())];
  [[EarlGrey selectElementWithMatcher:buttonMatcher] performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:buttonMatcher] assertWithMatcher:grey_selected()];
}

- (void)testTappingOnADisabledButton {
  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Disabled")]
      performAction:grey_tap()
      error:&error];
  XCTAssertEqualObjects(error.domain, kGREYInteractionErrorDomain);
  XCTAssertEqual(error.code, kGREYInteractionConstraintsFailedErrorCode);
}

#pragma mark - Private

- (void)ftr_dismissWindow:(UITapGestureRecognizer *)sender {
  [sender.view setHidden:YES];
}

@end
