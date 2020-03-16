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
#import "Synchronization/GREYAppStateTracker.h"

// These web view tests are not run by default since they require network access
// and have a possibility of flakiness.
@interface FTRLocalUIWebViewTest : FTRBaseIntegrationTest <UIWebViewDelegate>
@end

@implementation FTRLocalUIWebViewTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Web Views"];
}

// Test disabled on Xcode 9 beta. http://www.openradar.me/33383174
- (void)testSuccessiveTaps {
  if (iOS11_OR_ABOVE()) {
    return;
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadGoogle")]
      performAction:grey_tap()];
  [self ftr_waitForWebElementWithName:@"NEWS" elementMatcher:grey_accessibilityLabel(@"NEWS")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"NEWS")] performAction:grey_tap()];

  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"IMAGES")] performAction:grey_tap()
                                                                                  error:&error];
  if (error) {
    // On some form factors, label is set to "Images" instead of "IMAGES".
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Images")] atIndex:1]
        performAction:grey_tap()];
  }

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"VIDEOS")] performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"ALL")] performAction:grey_tap()];
}

// Test disabled on Xcode 9 beta. http://www.openradar.me/33383174
- (void)testAJAXLoad {
  if (iOS11_OR_ABOVE()) {
    return;
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadGoogle")]
      performAction:grey_tap()];
  [self ftr_waitForWebElementWithName:@"ALL" elementMatcher:grey_accessibilityLabel(@"ALL")];

  // Clicking on "Next page" triggers AJAX loading. On some form factors, label is set to "Next"
  // instead of "Next page".
  id<GREYMatcher> nextLabelMatcher =
      grey_anyOf(grey_accessibilityLabel(@"Next page"), grey_accessibilityLabel(@"Next"), nil);
  id<GREYMatcher> nextPageMatcher = grey_allOf(nextLabelMatcher, grey_interactable(), nil);
  NSError *error;
  [[[EarlGrey selectElementWithMatcher:nextPageMatcher]
         usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 200)
      onElementWithMatcher:grey_kindOfClass([UIWebView class])] performAction:grey_tap()
                                                                        error:&error];
  if (error) {
    id<GREYMatcher> moreResultsMatcher = grey_accessibilityLabel(@"More results");
    [[[EarlGrey selectElementWithMatcher:grey_allOf(moreResultsMatcher, grey_interactable(), nil)]
           usingSearchAction:grey_scrollInDirection(kGREYDirectionUp, 200)
        onElementWithMatcher:grey_kindOfClass([UIWebView class])] performAction:grey_tap()];
  } else {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"IMAGES")]
        assertWithMatcher:grey_sufficientlyVisible()];
  }
}

// Test disabled on Xcode 9 beta. http://www.openradar.me/33383174
- (void)testTextFieldInteraction {
  if (iOS11_OR_ABOVE()) {
    return;
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadGoogle")]
      performAction:grey_tap()];
  id<GREYMatcher> searchButtonMatcher = grey_accessibilityHint(@"Search");
  [self ftr_waitForWebElementWithName:@"Search" elementMatcher:searchButtonMatcher];
  [[[EarlGrey selectElementWithMatcher:searchButtonMatcher] performAction:grey_clearText()]
      performAction:grey_typeText(@"20 + 22\n")];

  [self ftr_waitForWebElementWithName:@"42" elementMatcher:grey_accessibilityLabel(@"42")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"42")]
      assertWithMatcher:grey_sufficientlyVisible()];

  // We need to tap because the second time we do typeAfterClearing, it passes firstResponder
  // check and never ends up auto-tapping on search field.
  [[EarlGrey selectElementWithMatcher:searchButtonMatcher] performAction:grey_tap()];

  [[[EarlGrey selectElementWithMatcher:searchButtonMatcher] performAction:grey_clearText()]
      performAction:grey_typeText(@"Who wrote Star Wars IV - A New Hope?\n")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Google Search")]
      performAction:grey_tap()];
  id<GREYMatcher> resultMatcher =
      grey_allOf(grey_accessibilityLabel(@"George Lucas"),
                 grey_accessibilityTrait(UIAccessibilityTraitHeader), nil);
  [self ftr_waitForWebElementWithName:@"Search Result" elementMatcher:resultMatcher];
  [[EarlGrey selectElementWithMatcher:resultMatcher] assertWithMatcher:grey_sufficientlyVisible()];
}

// Test disabled on Xcode 9 beta. http://www.openradar.me/33383174
- (void)testJavaScriptExecution {
  if (iOS11_OR_ABOVE()) {
    return;
  }
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"loadGoogle")]
      performAction:grey_tap()];
  id<GREYAction> jsAction =
      grey_javaScriptExecution(@"window.location.href='http://images.google.com'", nil);
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:jsAction];

  NSError *error;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"IMAGES")]
      assertWithMatcher:grey_sufficientlyVisible()
                  error:&error];
  if (error) {
    // On some form factors, label is set to "Images" instead of "IMAGES".
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"Images")] atIndex:1]
        assertWithMatcher:grey_sufficientlyVisible()];
  }

  NSString *executionString = @"window.location.href='http://translate.google.com'";
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:grey_javaScriptExecution(executionString, nil)];

  id<GREYAction> executeJavascript =
      grey_javaScriptExecution(@"window.location.href='http://play.google.com'", nil);
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:executeJavascript];

  NSString *jsResult;
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"FTRTestWebView")]
      performAction:grey_javaScriptExecution(@"2 + 2", &jsResult)];
  GREYAssertTrue([jsResult isEqualToString:@"4"], @"Expected: 4, Actual: %@", jsResult);
}

#pragma mark - Private

/**
 *  Waits for the element matching @c matcher to become visible or 3 seconds whichever happens
 *  first.
 *
 *  @param name    Name of the element to wait for.
 *  @param matcher Matcher that uniquely matches the element to wait for.
 */
- (void)ftr_waitForWebElementWithName:(NSString *)name elementMatcher:(id<GREYMatcher>)matcher {
  // TODO: Improve EarlGrey webview synchronization so that it automatically waits for the page to
  // load removing the need for conditions such as this.
  [[GREYCondition conditionWithName:[@"Wait For Element With Name: " stringByAppendingString:name]
                              block:^BOOL {
                                NSError *error = nil;
                                [[EarlGrey selectElementWithMatcher:matcher]
                                    assertWithMatcher:grey_sufficientlyVisible()
                                                error:&error];
                                return error == nil;
                              }] waitWithTimeout:3.0];
}

@end
