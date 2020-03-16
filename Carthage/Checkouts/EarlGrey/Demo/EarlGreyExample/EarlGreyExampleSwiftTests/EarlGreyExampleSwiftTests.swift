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

import EarlGrey
import XCTest

@testable import EarlGreyExampleSwift

class EarlGreyExampleSwiftTests: XCTestCase {

  func testBasicSelection() {
    // Select the button with Accessibility ID "clickMe".
    // This should throw a warning for "Result of Call Unused."
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
  }

  func testBasicSelectionAndAction() {
    // Select and tap the button with Accessibility ID "clickMe".
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .perform(grey_tap())
  }

  func testBasicSelectionAndAssert() {
    // Select the button with Accessibility ID "clickMe" and assert it's visible.
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .assert(grey_sufficientlyVisible())
  }

  func testBasicSelectionActionAssert() {
    // Select and tap the button with Accessibility ID "clickMe", then assert it's visible.
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .perform(grey_tap())
      .assert(grey_sufficientlyVisible())
  }

  func testSelectionOnMultipleElements() {
    // This test will fail because both buttons are visible and match the selection.
    // We add a custom error here to prevent the Test Suite failing.
    var error: NSError?
    EarlGrey.selectElement(with: grey_text("Non-Existent Element Text"))
      .perform(grey_tap(), error: &error)

    if let _ = error {
      print("Test Failed with Error : \(error.self!)")
    }
  }

  func testCollectionMatchers() {
    // First way to disambiguate: use collection matchers.
    let visibleSendButtonMatcher: GREYMatcher! =
        grey_allOf([grey_accessibilityID("ClickMe"), grey_sufficientlyVisible()])
    EarlGrey.selectElement(with: visibleSendButtonMatcher)
      .perform(grey_doubleTap())
  }

  func testWithInRoot() {
    // Second way to disambiguate: use inRoot to focus on a specific window or container.
    // There are two buttons with accessibility id "Send", but only one is inside SendMessageView.
    EarlGrey.selectElement(with: grey_accessibilityID("Send"))
      .inRoot(grey_kindOfClass(SendMessageView.self))
      .perform(grey_doubleTap())
  }

  func testWithCustomMatcher() {
    // Define the match condition: matches table cells that contains a date for a Thursday.
    let matches: MatchesBlock = { (element: Any?) -> Bool in
      if let cell = element as? UITableViewCell {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        if let date = formatter.date(from: cell.textLabel!.text!) {
          let calendar = Calendar.current
          let weekday = (calendar as NSCalendar).component(NSCalendar.Unit.weekday, from: date)
          return weekday == 5
        } else {
          return false
        }
      } else {
        return false
      }
    }

    // Create a description for the matcher.
    let describe: DescribeToBlock = { (description: Any) -> Void in
      let greyDescription:GREYDescription = description as! GREYDescription
      greyDescription.appendText("Date for a Thursday")
    }

    // Create an EarlGrey custom matcher.
    let matcherForThursday: GREYElementMatcherBlock! =
      GREYElementMatcherBlock.init(matchesBlock: matches, descriptionBlock: describe)
    // Profit
    EarlGrey.selectElement(with: matcherForThursday)
      .perform(grey_doubleTap())
  }

  func testTableCellOutOfScreen() {
    // Go find one cell out of the screen.
    EarlGrey.selectElement(with: grey_accessibilityID("Cell30"))
      .usingSearch(grey_scrollInDirection(GREYDirection.down, 100),
          onElementWith: grey_accessibilityID("table"))
      .perform(grey_tap())
    // Move back to top of the table.
    EarlGrey.selectElement(with: grey_accessibilityID("Cell1"))
      .usingSearch(grey_scrollInDirection(GREYDirection.up, 500),
          onElementWith: grey_accessibilityID("table"))
      .perform(grey_doubleTap())
  }

  func testCatchErrorOnFailure() {
    // TapMe doesn't exist, but the test doesn't fail because we are getting a pointer to the
    // error.
    var error: NSError?
    EarlGrey.selectElement(with: grey_accessibilityID("TapMe"))
      .perform(grey_tap(), error: &error)
    if let myError = error {
      print(myError)
    }
  }

  func testCustomAction() {
    // Fade in and out an element.
    let fadeInAndOut = { (element: UIView) -> Void in
      UIView.animate(withDuration: 1.0, delay: 0.0,
                     options: UIViewAnimationOptions.curveEaseOut,
                     animations: { element.alpha = 0.0 }, completion: {
            (finished: Bool) -> Void in
              UIView.animate(withDuration: 1.0,
                             delay: 0.0,
                             options: UIViewAnimationOptions.curveEaseIn,
                             animations: { element.alpha = 1.0 },
                             completion: nil)
      })
    }
    // Define a custom action that applies fadeInAndOut to the selected element.
    let tapClickMe: GREYActionBlock =
      GREYActionBlock.action(withName: "Fade In And Out", perform: {
        (element: Any?, errorOrNil: UnsafeMutablePointer<NSError?>?) -> Bool in
        // First make sure element is attached to a window.
        let elementAsView :UIView = element as! UIView
        guard let window = elementAsView.window! as UIView! else {
          let errorInfo = [NSLocalizedDescriptionKey:
            NSLocalizedString("Element is not attached to a window",
                              comment: "")]
          errorOrNil?.pointee = NSError(domain: kGREYInteractionErrorDomain,
                                        code: 1,
                                        userInfo: errorInfo)
          return false
        }
        fadeInAndOut(window)
        return true
      });
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .perform(tapClickMe)
  }

  func testWithCustomAssertion() {
    // Write a custom assertion that checks if the alpha of an element is equal to the expected
    // value.
    let alphaEqual = { (expectedAlpha: CGFloat) -> GREYAssertionBlock in
      return GREYAssertionBlock.assertion(withName: "Assert Alpha Equal",
                                          assertionBlockWithError: {
        (element: Any?, errorOrNil: UnsafeMutablePointer<NSError?>?) -> Bool in
        guard let view = element! as! UIView as UIView! else {
          let errorInfo = [NSLocalizedDescriptionKey:
            NSLocalizedString("Element is not a UIView",
                              comment: "")]
          errorOrNil?.pointee =
            NSError(domain: kGREYInteractionErrorDomain,
                    code: 2,
                    userInfo: errorInfo)
          return false
        }
        return view.alpha == expectedAlpha
      })
    }
    EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
      .assert(alphaEqual(1.0))
  }

  func testWithCustomFailureHandler() {
    // This test will fail and use our custom handler to handle the failure.
    // The custom handler is defined at the end of this file.
    let myHandler = SampleFailureHandler()
    EarlGrey.setFailureHandler(handler: myHandler)
    EarlGrey.selectElement(with: grey_accessibilityID("TapMe"))
      .perform(grey_tap())
  }

  func testLayout() {
    // Define a layout constraint.
    let onTheRight: GREYLayoutConstraint =
      GREYLayoutConstraint(attribute: GREYLayoutAttribute.left,
                           relatedBy: GREYLayoutRelation.greaterThanOrEqual,
                           toReferenceAttribute: GREYLayoutAttribute.right,
                           multiplier: 1.0,
                           constant: 0.0)
    EarlGrey.selectElement(with: grey_accessibilityLabel("SendForLayoutTest"))
      .assert(grey_layout([onTheRight], grey_accessibilityID("ClickMe")))
  }

  func testWithCondition() {
    let myCondition = GREYCondition.init(name: "Example condition", block: { () -> Bool in
      for j in 0...100000 {
        _ = j
      }
      return true
    })
    // Wait for my condition to be satisfied or timeout after 5 seconds.
    let success = myCondition.wait(withTimeout: 5)
    if !success {
      // Just printing for the example.
      print("Condition not met")
    } else {
      EarlGrey.selectElement(with: grey_accessibilityID("ClickMe"))
        .perform(grey_tap())
    }
  }

  func testWithGreyAssertions() {
    GREYAssert(1 == 1, reason: "Assert with GREYAssert")
    GREYAssertTrue(1 == 1, reason: "Assert with GREYAssertTrue")
    GREYAssertFalse(1 != 1, reason: "Assert with GREYAssertFalse")
    GREYAssertNotNil(1, reason: "Assert with GREYAssertNotNil")
    GREYAssertNil(nil, reason: "Assert with GREYAssertNil")
    GREYAssertEqualObjects(1, 1, reason: "Assert with GREYAssertEqualObjects")
    // Uncomment one of the following lines to fail the test.
    //GREYFail("Failing with GREYFail")
  }
}

class SampleFailureHandler : NSObject, GREYFailureHandler {
  /**
   *  Called by the framework to raise an exception.
   *
   *  @param exception The exception to be handled.
   *  @param details   Extra information about the failure.
   */
  public func handle(_ exception: GREYFrameworkException!, details: String!) {
    print("Test Failed With Reason : \(exception.reason!) and details \(details)")
  }
}
